%{
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "y.tab.h"
#define N 50
unsigned charCount = 1, lineCount = 1;
char lineContent[1024];
%}

symbol [.,:;\(\)\{\}\[\]]

operator \+\+|--|==|>=|<=|!=|&&|\|\||[+\-*\/%=<>!]

reserve_word boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|extends|false|final|finally|float|for|if|implements|int|long|main|new|print|private|protected|public|read|return|short|static|string|switch|this|true|try|void|while

id [A-Za-z_\$][A-Za-z0-9_\$]*
invalid_id [0-9^#]+[a-zA-Z_\$]+

integer ((0[Xx])[A-Fa-f0-9]+)|([0-9]+)
float (([0-9]*\.[0-9]+)|([0-9]+\.[0-9]*)|[0-9]+)([Ee][+-]?[0-9]+)?[Ff]?

invalid_str \"([^\"\r\n])*
str \"([^\"\\\n\r]|\\['\"\\btnfr0-7])*\"

invalid_char '([^\'\r\n])*
character '([^'\\\n\r]|\\['\"\\btnfr0-7])'

space [ \t]
eol \r?\n

comment (\/\/[^\n\r]*)|(\/\*([^*]|\*+[^*\/])*\*+\/)

%%

{eol} {
	printf("line %2d:%s\n", lineCount, lineContent);
	lineContent[0] = 0;
	lineCount++;
	charCount = 1;
}

{space} {
	charCount++;
}

{symbol} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
	if(strcmp(yytext, ".") == 0){
		return DOT;
	}else if(strcmp(yytext, ",") == 0){
		return COMMA;
	}else if(strcmp(yytext, ":") == 0){
		return COLON;
	}else if(strcmp(yytext, ";") == 0){
		return SEMI;
	}else if(strcmp(yytext, "(") == 0){
		return LP;
	}else if(strcmp(yytext, ")") == 0){
		return RP;
	}else if(strcmp(yytext, "{") == 0){
		return LC;
	}else if(strcmp(yytext, "}") == 0){
		return RC;
	}else if(strcmp(yytext, "[") == 0){
		return LB;
	}else if(strcmp(yytext, "]") == 0){
		return RB;
	}
}

{comment} {
	strcat(lineContent, " ");
	for(int i = 0; yytext[i]; i++){
		charCount++;
		strcat(lineContent, (char[2]){yytext[i] , '\0'});
		if(yytext[i] == '\n'){
			printf("line %2d:%s", lineCount, lineContent);
			lineContent[0] = 0;
			strcat(lineContent, " ");
			lineCount++;
			charCount = 1;
		}
	}
}

{operator} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
	if(strcmp(yytext, "++") == 0){
		return DADD;
	}else if(strcmp(yytext, "--") == 0){
		return DSUB;
	}else if(strcmp(yytext, "==") == 0){
		return EQ;
	}else if(strcmp(yytext, ">=") == 0){
		return BEQ;
	}else if(strcmp(yytext, "<=") == 0){
		return LEQ;
	}else if(strcmp(yytext, "!=") == 0){
		return NEQ;
	}else if(strcmp(yytext, "&&") == 0){
		return AND;
	}else if(strcmp(yytext, "||") == 0){
		return OR;
	}else if(strcmp(yytext, "+") == 0){
		return ADD;
	}else if(strcmp(yytext, "-") == 0){
		return SUB;
	}else if(strcmp(yytext, "*") == 0){
		return MUL;
	}else if(strcmp(yytext, "/") == 0){
		return DIV;
	}else if(strcmp(yytext, "%") == 0){
		return MOD;
	}else if(strcmp(yytext, "=") == 0){
		return ASSIGN;
	}else if(strcmp(yytext, "<") == 0){
		return LT;
	}else if(strcmp(yytext, ">") == 0){
		return BT;
	}else if(strcmp(yytext, "!") == 0){
		return NOT;
	}
}

{reserve_word} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
	if(strcmp(yytext, "boolean") == 0){
		return BOOLEAN;
	}else if(strcmp(yytext, "break") == 0){
		return BREAK;
	}else if(strcmp(yytext, "byte") == 0){
		return BYTE;
	}else if(strcmp(yytext, "case") == 0){
		return CASE;
	}else if(strcmp(yytext, "char") == 0){
		return CHAR;
	}else if(strcmp(yytext, "catch") == 0){
		return CATCH;
	}else if(strcmp(yytext, "class") == 0){
		return CLASS;
	}else if(strcmp(yytext, "const") == 0){
		return CONST;
	}else if(strcmp(yytext, "continue") == 0){
		return CONTINUE;
	}else if(strcmp(yytext, "default") == 0){
		return DEFAULT;
	}else if(strcmp(yytext, "do") == 0){
		return DO;
	}else if(strcmp(yytext, "double") == 0){
		return DOUBLE;
	}else if(strcmp(yytext, "else") == 0){
		return ELSE;
	}else if(strcmp(yytext, "extends") == 0){
		return EXTENDS;
	}else if(strcmp(yytext, "false") == 0){
		return FALSE;
	}else if(strcmp(yytext, "final") == 0){
		return FINAL;
	}else if(strcmp(yytext, "finally") == 0){
		return FINALLY;
	}else if(strcmp(yytext, "float") == 0){
		return FLOAT;
	}else if(strcmp(yytext, "for") == 0){
		return FOR;
	}else if(strcmp(yytext, "if") == 0){
		return IF;
	}else if(strcmp(yytext, "implements") == 0){
		return IMPLEMENTS;
	}else if(strcmp(yytext, "int") == 0){
		return INT;
	}else if(strcmp(yytext, "long") == 0){
		return LONG;
	}else if(strcmp(yytext, "main") == 0){
		return MAIN;
	}else if(strcmp(yytext, "new") == 0){
		return NEW;
	}else if(strcmp(yytext, "print") == 0){
		return PRINT;
	}else if(strcmp(yytext, "protected") == 0){
		return PROTECTED;
	}else if(strcmp(yytext, "private") == 0){
		return PRIVATE;
	}else if(strcmp(yytext, "public") == 0){
		return PUBLIC;
	}else if(strcmp(yytext, "return") == 0){
		return RETURN;
	}else if(strcmp(yytext, "read") == 0){
		return READ;
	}else if(strcmp(yytext, "short") == 0){
		return SHORT;
	}else if(strcmp(yytext, "static") == 0){
		return STATIC;
	}else if(strcmp(yytext, "string") == 0){
		return STRING;
	}else if(strcmp(yytext, "switch") == 0){
		return SWITCH;
	}else if(strcmp(yytext, "this") == 0){
		return THIS;
	}else if(strcmp(yytext, "true") == 0){
		return TRUE;
	}else if(strcmp(yytext, "try") == 0){
		return TRY;
	}else if(strcmp(yytext, "void") == 0){
		return VOID;
	}else if(strcmp(yytext, "while") == 0){
		return WHILE;
	}
}

{integer} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
	return NUM;
}

{float} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
	return FNUM;
}

{invalid_str} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
}

{str} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
	return STR;
}

{invalid_char} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
}

{character} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
	return CH;
}

{invalid_id} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
}

{id} {
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
	yylval.strval = strdup(yytext);
	return ID;
}

. {
	printf("******Line: %d, 1st char: %d, \"%s\" is an invalid token******\n", lineCount, charCount, yytext);
	strcat(lineContent, " ");
	strcat(lineContent, yytext);
	charCount += yyleng;
}

%%

