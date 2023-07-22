%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define N 50
unsigned charCount = 1, lineCount = 1, sub = 0;

typedef struct symtab{
	int index;
	char *name;
	struct symtab *next;
}Symtab, *pSymtab;
pSymtab symbolTable;

pSymtab create();
int lookup(char *s);
int insert(char *s);
void dump();
%}

symbol [,:;\(\)\{\}\[\]]

operator \+\+|--|==|>=|<=|!=|&&|\|\||<<|>>|>>>|[+\-*\/%=<>!&|^~]

reserve_word abstract|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|extends|false|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|main|native|new|package|print|private|protected|public|return|short|static|string|super|switch|synchronized|this|throw|throws|transient|true|try|void|volatile|while

integer ([+-][ ]*)?(((0[Xx])[A-Fa-f0-9]+)|([0-9]+))

float ([+-][ ]*)?(([0-9]*\.[0-9]+)|([0-9]+\.[0-9]*)|[0-9]+)([Ee][+-]?[0-9]+)?[Ff]?

invalid_str \"([^\"\r\n])*
str \"([^\"\\\n\r]|\\['\"\\btnfr0-7])*\"

invalid_char '([^\'\r\n])*
character '([^'\\\n\r]|\\['\"\\btnfr0-7])'

id [A-Za-z_\$][A-Za-z0-9_\$]*
invalid_id [0-9^#]+[a-zA-Z_\$]+

space [ \t]
eol \r?\n

comment (\/\/[^\n\r]*)|(\/\*([^*]|\*+[^*\/])*\*+\/)

%%

{eol} {
	sub = 0;
	lineCount ++;
	charCount = 1;
}

{space} {
	charCount ++;
}

{symbol} {
	if(yytext[0] != ')'){
		sub = 0;
	}
	printf("Line: %d, 1st char: %d, \"%s\" is a \"symbol\".\n", lineCount, charCount, yytext);
	charCount += yyleng;
}

{comment} {
	printf("Line: %d, 1st char: %d, \"%s\" is a \"comment\".\n", lineCount, charCount, yytext);
	for(int i = 0; yytext[i]; i++){
		charCount++;
		if(yytext[i] == '\n'){
			lineCount++;
			charCount = 1;
		}
	}
}

{operator} {
	sub = 0;
	printf("Line: %d, 1st char: %d, \"%s\" is an \"operator\".\n", lineCount, charCount, yytext);
	charCount += yyleng;
}

{reserve_word} { 
	sub = 0;
	printf("Line: %d, 1st char: %d, \"%s\" is a \"reserved word\".\n", lineCount, charCount, yytext);
	charCount += yyleng;
}

{integer} {
	if(sub == 1 && (yytext[0] == '-' || yytext[0] == '+')){
		printf("Line: %d, 1st char: %d, \"%c\" is an \"operator\".\n", lineCount, charCount, yytext[0]);
		for(;yytext[0] == '-' || yytext[0] == '+' || yytext[0] == ' '; yytext++){
			charCount++;
			yyleng--;
		}
	}
	printf("Line: %d, 1st char: %d, \"%s\" is an \"integer\".\n", lineCount, charCount, yytext);
	sub = 1;
	charCount += yyleng;
}

{float} {
	if(sub == 1 && (yytext[0] == '-' || yytext[0] == '+')){
		printf("Line: %d, 1st char: %d, \"%c\" is an \"operator\".\n", lineCount, charCount, yytext[0]);
		for(;yytext[0] == '-' || yytext[0] == '+' || yytext[0] == ' '; yytext++){
			charCount++;
			yyleng--;
		}
	}
	printf("Line: %d, 1st char: %d, \"%s\" is a \"float\".\n", lineCount, charCount, yytext);
	sub = 1;
	charCount += yyleng;
}

{invalid_str} {
	printf("Line: %d, 1st char: %d, %s is an \"Invalid string\".\n", lineCount, charCount, yytext);
	charCount += yyleng;
}

{str} { 
	sub = 1;
	yytext[yyleng-1] = '\0';
	yytext++;
	printf("Line: %d, 1st char: %d, \"%s\" is a \"string\".\n", lineCount, charCount+1, yytext);
	charCount += yyleng;
}

{invalid_char} {
	printf("Line: %d, 1st char: %d, %s is an \"Invalid chatacter\".\n", lineCount, charCount, yytext);
	charCount += yyleng;
}

{character} { 
	sub = 1;
	yytext[yyleng-1] = '\0';
	yytext++;
	printf("Line: %d, 1st char: %d, \"%s\" is a \"character\".\n", lineCount, charCount+1, yytext);
	charCount += yyleng;
}

{invalid_id} {
	printf("Line: %d, 1st char: %d, \"%s\" is an \"Invalid ID\".\n", lineCount, charCount, yytext);
	charCount += yyleng;
}

{id} {
	sub = 1;
	printf("Line: %d, 1st char: %d, \"%s\" is an \"ID\".\n", lineCount, charCount, yytext);
	insert(yytext);
	charCount += yyleng;
}

. {
	printf("Line: %d, 1st char: %d, \"%s\" is an \"Invalid token\".\n", lineCount, charCount, yytext); 
	charCount += yyleng;
}

%%

pSymtab create(){
	return NULL;
}

int lookup(char *s){
	if(symbolTable){
		for(pSymtab p = symbolTable; p != NULL; p = p->next){
			if(strcmp(p->name, s) == 0){
				return p->index;
			}
		}
	}
	return -1;
}

int insert(char *s){
	if(symbolTable){
		pSymtab tail;
		for(pSymtab p = symbolTable; p != NULL; p = p->next){
			tail = p;
			if(strcmp(p->name, s) == 0){
				return p->index;
			}
		}
		pSymtab newSym = (pSymtab)malloc(sizeof(Symtab));
		newSym->name = (char *)malloc(N * sizeof(char));
		newSym->index = tail->index + 1;
		strcpy(newSym->name, s);
		newSym->next = NULL;
		tail->next = newSym;
		return newSym->index;
	}else{
		pSymtab newSym = (pSymtab)malloc(sizeof(Symtab));
		newSym->name = (char *)malloc(N * sizeof(char));
		newSym->index = 0;
		strcpy(newSym->name, s);
		newSym->next = NULL;
		symbolTable = newSym;
		return newSym->index;
	}
}

void dump(){
	printf("The symbol table contains:\n");
	if(symbolTable){
		for(pSymtab p = symbolTable; p != NULL; p = p->next){
			printf("%s\n", p->name);
		}
	}
}

int main(){
	symbolTable = create();
	yylex();
	dump();
	return 0;
}
