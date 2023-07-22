%error-verbose
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define N 50
int yylex();

extern unsigned charCount, lineCount;
char classTab[N][N], funcTab[N][N], varTab[N][N];	//symbol table
int classNum = 0, funcNum = 0, varNum = 0;			//number of element in symbol table
int classScope[N], funcScope[N], varScope[N];		//scope layer
int classIndex = 0, funcIndex = 0, varIndex = 0;	//number of element in symbol layer
int preDeclare = 0, preDeclareNum = 0;				//predeclare before curly brackets
char undefClass[N][N];								//object created before type defined
int undefClassState[N][2], undefClassNum = 0;		//undefClassState[N][0] = 1(type defined), other(type not defined)
													//undefClassState[N][1] = the line where the object was created
void yyerror(const char*);
int classExistinLocal(char *s);
int funcExistinLocal(char *s);
int varExistinLocal(char *s);
int classExistinGlobal(char *s);
int funcExistinGlobal(char *s);
int varExistinGlobal(char *s);
int checkClass(char *s);
int checkFunc(char *s);
int checkVar(char *s);
void addClass(char *s);
void addFunc(char *s);
void addVar(char *s);
void checkUndefClass(int i);
void enterScope();
void exitScope();
void undefClassErr();
void undefIDErr(char *s);
void redefIDErr(char *s);
%}
%union{
	char *strval;
}
%token BOOLEAN BREAK BYTE CASE CHAR CATCH CLASS CONST CONTINUE DEFAULT DO DOUBLE ELSE EXTENDS FALSE FINAL FINALLY FLOAT FOR IF IMPLEMENTS INT LONG MAIN NEW PRINT PRIVATE PROTECTED PUBLIC RETURN READ SHORT STATIC STRING SWITCH THIS TRUE TRY VOID WHILE
%token COMMA COLON SEMI LP RP LC RC LB RB DOT
%token DADD DSUB EQ BEQ LEQ NEQ AND OR NOT ADD SUB MUL DIV MOD ASSIGN LT BT
%token FNUM STR NUM CH
%token <strval> ID
%start classes
%%
//一個檔案可以有多個 classes, 若遇到 error 則會處理 error
classes:
	| classes class
	| error
	;
//class 的宣告格式
class: CLASS ID{ addClass($2); } LC{ enterScope(); } elements RC{ exitScope(); };
//每個 class body 可以由多個 elements 組成
elements: 
	| elements element
	;
//一個 element 可以是 field、method 或 classe
element: field | method | class;
//field 可以是變數宣告、陣列宣告或物件宣告
field: STATIC type variableList SEMI
	| CONST type variableList SEMI
	| FINAL type variableList SEMI
	| type variableList SEMI
	| type LB RB ID ASSIGN NEW type LB NUM RB SEMI{ addVar($4); }	//create an array
	| ID ID ASSIGN NEW ID LP RP SEMI{								//create an object
		strcpy(undefClass[undefClassNum], (char*)$1);
		undefClassState[undefClassNum][0] = 0;
		undefClassState[undefClassNum++][1] = lineCount;
		addVar($2);
	};
//variable 的基本資料型態
type: INT | FLOAT | BOOLEAN | CHAR | STRING | LONG | SHORT | VOID | DOUBLE;
//可一次宣告多個 variable，但至少需宣告一個
variableList: variable 
	| variableList COMMA variable
	;
//變數宣告可以選擇 assign 值
variable: ID{ addVar($1); }
	| ID ASSIGN expr{ addVar($1); }
	;
//method declaration 的宣告格式, 可能以選擇在前面加上 modifier
method: modifier type ID{ addFunc($3); } LP argus RP compound	//with modifier
	| type ID{ addFunc($2); } LP argus RP compound				//without modifier
	| VOID MAIN{ addFunc("main"); } LP argus RP compound		//void main()	
	| MAIN{ addFunc("main"); } LP argus RP compound				//main()
	;
//method modifier 可以是 public、protected 或 private
modifier: PUBLIC | PROTECTED | PRIVATE;
//可一次傳入多個 arguments, 以逗號分格
argus: argu
	| argus COMMA argu
	;
//一個 argument 必須包含型態和參數名稱，也可以不傳入 argument
argu:
	| type ID{ preDeclare = 1; addVar($2); preDeclareNum++; } //此處 argument 是在大括號外宣告，需特別處裡
	;
//***compound statement: compound 裡可能有多個statements
compound: LC{ enterScope(); } statements RC{ exitScope(); }; //大括號內宣告的變數只能在 local scope 使用
//compound statement 除了 statements 之外也可以有 fields 和 classes，但不能有 methods
statements: 
	| statements class
	| statements field
	| statements statement
	;
//共有六種 statements，其中 return 合併到 simple，method call 合併到 factor
statement: compound | simple | condition | for | while;
//***simple statement: name++ 和 name-- 已經在 factor 中定義，因此從 simple 中移除
simple: ID ASSIGN expr SEMI{ checkVar($1); }
	| ID DOT ID ASSIGN expr SEMI{ checkVar($1); checkVar($3); }
	| PRINT LP expr RP SEMI
	| READ LP ID RP SEMI{ checkVar($3); }
	| READ LP ID DOT ID RP SEMI{ checkVar($3); checkVar($5); }
	| expr SEMI
	| RETURN expr SEMI	//***return statement
	;
//expression 處理加減法
expr: term | expr ADD term | expr SUB term;
//term 處理乘除法
term: factor | term MUL factor | term DIV factor;
//factor 為可以被運算單元，包含 variables、array element、constant expression，(expression) 和 method call
factor: ID
	| prefixOp ID
	| ID postfixOp
	| ID LB expr RB
	| prefixOp ID LB expr RB
	| ID LB expr RB postfixOp
	| constExpr
	| LP expr RP
	| methodInvocation
	;
//prefixOp的 ADD 和 SUB 是 variable 的正負號
prefixOp: DADD | DSUB | ADD | SUB;
postfixOp: DADD | DSUB;
//constExpr的 ADD 和 SUB 是數字的正負號，因為數字 tokens 都是以無號數的格式被讀取
constExpr: NUM | ADD NUM | SUB NUM | FNUM | ADD FNUM | SUB FNUM | STR;
//***method invocation statement: 可傳入多個 experssions
methodInvocation: ID LP exprs RP{ checkFunc($1); }
	| ID DOT ID LP exprs RP{ checkVar($1); checkFunc($3); }
	;
//傳入的 experssions 需以逗號分隔，也可以不傳入 
exprs:
	| expr
	| exprs COMMA expr
	;
//***conditional statement: 為避免 shift/reduce conflict，需將 stataments 所有可能情況列出
condition: IF LP booleanExpr RP simple
	| IF LP booleanExpr RP simple ELSE compound
	| IF LP booleanExpr RP simple ELSE simple
	| IF LP booleanExpr RP compound
	| IF LP booleanExpr RP compound ELSE simple
	| IF LP booleanExpr RP compound ELSE compound
	;
booleanExpr: expr infixOp expr;
infixOp: EQ | NEQ | LT | BT | LEQ | BEQ;
//***loop statement: 分為 while loop 和 for loop
while: WHILE LP booleanExpr RP statement | error RC; //由於有遇到while 有error時,沒抓好scope的情形,所以加上了error RC
for: FOR LP forInitList SEMI booleanExpr SEMI forUpdate RP statement;
//forInitList 可以擺放多個 assignments
forInitList: forInit
	| forInitList COMMA forInit;
//forInit 可以assign新宣告的 variable 或已存在的 variable 或已存在的 array element
forInit: ID ASSIGN expr { checkVar($1); }
	| INT ID ASSIGN expr{ preDeclare = 1; addVar($2); preDeclareNum++; } //此處 variable 是在大括號外宣告，需特別處裡
	| ID LB expr RB ASSIGN expr{ checkVar($1); }
	;
//forUpdate 可擺放的 factor 有 variable 和 array element
forUpdate: ID DADD{ checkVar($1); }
	| ID DSUB{ checkVar($1); }
	| ID LB expr RB DADD{ checkVar($1); }
	| ID LB expr RB DSUB{ checkVar($1); }
	;
%%
int main(){
	yyparse();
	undefClassErr();
	return 0;
}
void yyerror(const char *str){
	fprintf(stderr, "******Line %d: 1st char %d has %s******\n", lineCount, charCount, str+14);
}
int classExistinLocal(char *s){	//return 0代表沒有宣告過(accept) 1代表有宣告過(error)
	for(int i=classScope[classIndex-1]; i<classNum; i++){
		if(strcmp(s, classTab[i]) == 0){
			return 1;
		}
	}
	return 0;	
}
int funcExistinLocal(char *s){	//return 0代表沒有宣告過(accept) 1代表有宣告過(error)
	for(int i=funcScope[funcIndex-1]; i<funcNum; i++){
		if(strcmp(s, funcTab[i]) == 0){
			return 1;
		}
	}
	return 0;	
}
int varExistinLocal(char *s){	//return 0代表沒有宣告過(accept) 1代表有宣告過(error)
	for(int i=varScope[varIndex-1]; i<varNum; i++){
		if(strcmp(s, varTab[i]) == 0){
			return 1;
		}
	}
	return 0;	
}
int classExistinGlobal(char *s){	//return 0代表沒有宣告過(error) 1代表有宣告過(accept)
	for(int i=0; i<classNum; i++){
		if(strcmp(s, classTab[i]) == 0){
			return 1;
		}
	}
	return 0;
}
int funcExistinGlobal(char *s){	//return 0代表沒有宣告過(error) 1代表有宣告過(accept)
	for(int i=0; i<funcNum; i++){
		if(strcmp(s, funcTab[i]) == 0){
			return 1;
		}
	}
	return 0;
}
int varExistinGlobal(char *s){	//return 0代表沒有宣告過(error) 1代表有宣告過(accept)
	for(int i=0; i<varNum; i++){
		if(strcmp(s, varTab[i]) == 0){
			return 1;
		}
	}
	return 0;
}
int checkClass(char *s){	//確保class在global scope內有被宣告過(代表可使用)
	if(!classExistinGlobal(s)){	//沒有宣告過
		undefIDErr(s);
		return 0;
	}
	return 1;
}
int checkFunc(char *s){		//確保function在global scope內有被宣告過(代表可使用)
	if(!funcExistinGlobal(s)){	//沒有宣告過
		undefIDErr(s);
		return 0;
	}
	return 1;
}
int checkVar(char *s){		//確保variable在global scope內有被宣告過(代表可使用)
	if(!varExistinGlobal(s)){	//沒有宣告過
		undefIDErr(s);
		return 0;
	}
	return 1;
}
void addClass(char *s){	//確保class在local scope內沒有被宣告過(代表可宣告),若無重複宣告則加入classTab
	if(classExistinLocal(s)){	//重複宣告
		redefIDErr(s);
	}else{	//沒有宣告過
		strcpy(classTab[classNum++], s);
	}
}
void addFunc(char *s){	//確保function在local scope內沒有被宣告過(代表可宣告),若無重複宣告則加入funcTab
	if(funcExistinLocal(s)){	//重複宣告
		redefIDErr(s);
	}else{	//沒有宣告過
		strcpy(funcTab[funcNum++], s);
	}
}
void addVar(char *s){	//確保variable在local scope內沒有被宣告過(代表可宣告),若無重複宣告則加入varTab
	if(preDeclare == 1){	//在ForInitOpt或method argument list內宣告的variable
		strcpy(varTab[varNum++], s);
	}else{
		if(varExistinLocal(s)){	//重複宣告
			redefIDErr(s);
		}else{	//沒有宣告過
			strcpy(varTab[varNum++], s);
		}
	}
}
void checkUndefClass(int i){
	for(int j=0; j<classNum; j++){
		if(strcmp(undefClass[i], classTab[j]) == 0){
			undefClassState[i][0] = 1;
		}
	}
}
void enterScope(){
	classScope[classIndex++] = classNum;
	funcScope[funcIndex++] = funcNum; 
	varScope[varIndex++ - preDeclareNum] = varNum;
	preDeclareNum = 0;
	for(int i=0; i<undefClassNum; i++){
		if(undefClassState[i][0] != 1){
			undefClassState[i][0]--;
		}
	}
}
void exitScope(){
	for(int i=0; i<undefClassNum; i++){
		if(undefClassState[i][0] == 0){
			checkUndefClass(i);
		}else if(undefClassState[i][0] != 1){
			undefClassState[i][0]++;
		}
	}
	classNum = classScope[--classIndex];
	funcNum = funcScope[--funcIndex];
	varNum = varScope[--varIndex];
}
void undefClassErr(){
	for(int i=0; i<undefClassNum; i++){
		if(undefClassState[i][0] != 1){
			fprintf(stderr, "******Line %d: \'%s\' hasn't been declared yet******\n", undefClassState[i][1], undefClass[i]);
		}
	}
}
void undefIDErr(char* errID){		//使用到未宣告的ID
	fprintf(stderr, "******Line %d: \'%s\' hasn't been declared yet******\n", lineCount, errID);
}
void redefIDErr(char* errID){		//有重複宣告的ID
	fprintf(stderr, "******Line %d: \'%s\' is a duplicate identifier******\n", lineCount, errID);
}
