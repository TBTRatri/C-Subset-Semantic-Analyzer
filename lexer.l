%option noyywrap

%{
#include <iostream>
#include <string>
#include <fstream>
#include "symbol_info.h"

/* CRITICAL FOR MAC: Define YYSTYPE as a pointer BEFORE including y.tab.h */
#define YYSTYPE symbol_info*

#include "y.tab.h"

using namespace std;

extern YYSTYPE yylval;
extern int lines;
extern int error_count; // Lab 3: Error count track korar jonno [cite: 38]
extern ofstream error_file; // Lab 3: Semantic/Lexical error file [cite: 36]

void yyerror(const char *);
%}

/* Definitions */
delim    [ \t\v\r\f]
newline  \r?\n
ws       {delim}+
letter_  [A-Za-z_]
digit    [0-9]
id       {letter_}({letter_}|{digit})*
integers {digit}+
floats   {digit}*(\.{digit}+)|{digit}*(\.{digit}+)?((E|e)[-]?{digit}+)

%%

{ws}        { /* ignore whitespace */ }
{newline}   { lines++; }

"if"        { return IF; }
"else"      { return ELSE; }
"for"       { return FOR; }
"while"     { return WHILE; }
"do"        { return DO; }
"break"     { return BREAK; }
"continue"  { return CONTINUE; }
"return"    { return RETURN; }
"int"       { return INT; }
"float"     { return FLOAT; }
"char"      { return CHAR; }
"void"      { return VOID; }
"double"    { return DOUBLE; }
"switch"    { return SWITCH; }
"case"      { return CASE; }
"default"   { return DEFAULT; }
"printf"    { return PRINTLN; }

"+"|"-"     {
                yylval = new symbol_info(yytext, "ADDOP");
                return ADDOP;
            }
"*"|"/"|"%" {
                yylval = new symbol_info(yytext, "MULOP");
                return MULOP;
            }
"++"        { return INCOP; }
"--"        { return DECOP; }
"<"|">"|"<="|">="|"=="|"!=" {
                yylval = new symbol_info(yytext, "RELOP");
                return RELOP;
            }

"="         { return ASSIGNOP; }
"&&"|"||"   {
                yylval = new symbol_info(yytext, "LOGICOP");
                return LOGICOP;
            }

"!"         { return NOT; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LCURL; }
"}"         { return RCURL; }
"["         { return LTHIRD; }
"]"         { return RTHIRD; }
";"         { return SEMICOLON; }
","         { return COMMA; }

{id}        {
                yylval = new symbol_info(yytext, "ID");
                return ID;
            }
{integers}  {
                yylval = new symbol_info(yytext, "CONST_INT");
                return CONST_INT;
            }
{floats}    {
                yylval = new symbol_info(yytext, "CONST_FLOAT");
                return CONST_FLOAT;
            }

.           { 
                /* Lexical error handle korar jonno [cite: 40, 43] */
                error_count++;
                error_file << "Error at line " << lines << ": Unrecognized character " << yytext << endl;
            }

%%
