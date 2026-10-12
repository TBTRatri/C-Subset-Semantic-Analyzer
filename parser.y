%{
#include "symbol_table.h"
#include <cstring>
#include <iostream>
#include <vector>
#include <string>
#include <fstream>

#define YYSTYPE symbol_info*

using namespace std;

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

symbol_table *table;
string current_type;
vector<pair<string, string>> current_func_params;
vector<string> argument_types; 

int lines = 1;
int error_count = 0;
ofstream outlog;
ofstream error_file; 

void yyerror(const char *s) {
    outlog << "Error at line " << lines << ": " << s << endl << endl;
}

void semantic_error(string message) {
    error_count++;
    error_file << "Error at line " << lines << ": " << message << endl;
}

bool is_function_declared(string name) {
    symbol_info* result = table->lookup(name); 
    return (result != nullptr && result->get_is_function());
}

bool is_variable_declared_current_scope(string name) {
    symbol_info* result = table->lookup_current_scope(name);
    return (result != nullptr);
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program {
    outlog << "At line no: " << lines << " start : program " << endl << endl;
} ;

program : program unit | unit ;

unit : var_declaration | func_definition ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN {
    if(table->lookup_current_scope($2->getname())) {
        semantic_error("Multiple declaration of " + $2->getname());
    } else {
        symbol_info* func = new symbol_info($2->getname(), "ID", $1->getname());
        func->set_as_function($1->getname(), current_func_params);
        table->insert(func);
    }
} compound_statement {
    $$ = new symbol_info($1->getname() + " " + $2->getname() + "(" + $4->getname() + ")" + $7->getname(), "func_def");
    current_func_params.clear();
} ;

parameter_list : parameter_list COMMA type_specifier ID {
    $$ = new symbol_info($1->getname() + "," + $3->getname() + " " + $4->getname(), "param_list");
    current_func_params.push_back({$3->getname(), $4->getname()});
}
| type_specifier ID {
    $$ = new symbol_info($1->getname() + " " + $2->getname(), "param_list");
    current_func_params.push_back({$1->getname(), $2->getname()});
}
| type_specifier {
    current_func_params.push_back({$1->getname(), ""});
}
| { $$ = new symbol_info("", "param_list"); } ;

compound_statement : LCURL {
    table->enter_scope();
    for(auto p : current_func_params) {
        if(p.second != "") table->insert(new symbol_info(p.second, "ID", p.first));
    }
} statements RCURL {
    table->print_all_scopes(outlog);
    table->exit_scope();
    $$ = new symbol_info("{\n" + $3->getname() + "\n}", "comp_stmnt");
} ;

var_declaration : type_specifier declaration_list SEMICOLON {
    if($1->getname() == "void") semantic_error("Variable type cannot be void");
    $$ = new symbol_info($1->getname() + " " + $2->getname() + ";", "var_dec");
} ;

type_specifier : INT { $$ = new symbol_info("int", "type"); current_type = "int"; }
| FLOAT { $$ = new symbol_info("float", "type"); current_type = "float"; }
| VOID { $$ = new symbol_info("void", "type"); current_type = "void"; } ;

declaration_list : declaration_list COMMA ID {
    if(is_variable_declared_current_scope($3->getname())) {
        semantic_error("Multiple declaration of " + $3->getname());
    } else {
        table->insert(new symbol_info($3->getname(), "ID", current_type));
    }
}
| ID {
    if(is_variable_declared_current_scope($1->getname())) {
        semantic_error("Multiple declaration of " + $1->getname());
    } else {
        table->insert(new symbol_info($1->getname(), "ID", current_type));
    }
} ;

statements : statement { 
    $$ = new symbol_info($1->getname(), "stmnts"); 
}
| statements statement { 
    $$ = new symbol_info($1->getname() + "\n" + $2->getname(), "stmnts"); 
} ;

statement : var_declaration | expression_statement | compound_statement 
| RETURN expression SEMICOLON { 
    $$ = new symbol_info("return " + $2->getname() + ";", "stmnt"); 
}
| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
    $$ = new symbol_info("if(" + $3->getname() + ")\n" + $5->getname(), "stmnt");
}
| WHILE LPAREN expression RPAREN statement {
    $$ = new symbol_info("while(" + $3->getname() + ")\n" + $5->getname(), "stmnt");
} ;

expression_statement : SEMICOLON { $$ = new symbol_info(";", "expr_stmt"); }
| expression SEMICOLON { $$ = new symbol_info($1->getname() + ";", "expr_stmt"); } ;

expression : logic_expression { $$ = $1; }
| variable ASSIGNOP logic_expression {
    if($1->get_data_type() == "int" && $3->get_data_type() == "float") {
        semantic_error("Warning: possible loss of data in assignment of float to int");
    }
    $$ = new symbol_info($1->getname() + "=" + $3->getname(), "expr", $1->get_data_type());
} ;

logic_expression : rel_expression { $$ = $1; } ;

rel_expression : simple_expression { $$ = $1; }
| simple_expression RELOP simple_expression {
    $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "rel_expr", "int");
} ;

simple_expression : term { $$ = $1; }
| simple_expression ADDOP term {
    string ret_type = ($1->get_data_type() == "float" || $3->get_data_type() == "float") ? "float" : "int";
    $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "simp_expr", ret_type);
} ;

term : unary_expression { $$ = $1; }
| term MULOP unary_expression {
    if($2->getname() == "%") {
        if($1->get_data_type() != "int" || $3->get_data_type() != "int") {
            semantic_error("Non-Integer operand on modulus operator");
        }
        if($3->getname() == "0") semantic_error("Modulus by zero");
        $$ = new symbol_info($1->getname() + "%" + $3->getname(), "term", "int");
    } else {
        string ret_type = ($1->get_data_type() == "float" || $3->get_data_type() == "float") ? "float" : "int";
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "term", ret_type);
    }
} ;

unary_expression : factor { $$ = $1; }
| ADDOP unary_expression { $$ = $2; }
| NOT unary_expression { $$ = new symbol_info("!" + $2->getname(), "un_expr", "int"); } ;

factor : variable { $$ = $1; }
| CONST_INT { $$ = new symbol_info($1->getname(), "fctr", "int"); }
| CONST_FLOAT { $$ = new symbol_info($1->getname(), "fctr", "float"); }
| ID LPAREN argument_list RPAREN {
    symbol_info* res = table->lookup($1->getname());
    if(res == nullptr) semantic_error("Undeclared function " + $1->getname());
    $$ = new symbol_info($1->getname() + "(" + $3->getname() + ")", "fctr", res ? res->get_return_type() : "void");
    argument_types.clear();
}
| variable INCOP { $$ = $1; }
| variable DECOP { $$ = $1; } ;

argument_list : arguments { $$ = $1; } | { $$ = new symbol_info("", "arg_list"); } ;

arguments : arguments COMMA logic_expression {
    argument_types.push_back($3->get_data_type());
}
| logic_expression {
    argument_types.push_back($1->get_data_type());
} ;

variable : ID {
    symbol_info* res = table->lookup($1->getname());
    if(res == nullptr) semantic_error("Undeclared variable " + $1->getname());
    $$ = new symbol_info($1->getname(), "varbl", res ? res->get_data_type() : "void");
}
| ID LTHIRD expression RTHIRD {
    symbol_info* res = table->lookup($1->getname());
    if(res && !res->get_is_array()) semantic_error($1->getname() + " is not an array");
    if($3->get_data_type() != "int") semantic_error("Array index must be an integer");
    $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "varbl", res ? res->get_data_type() : "void");
} ;

%%

int main(int argc, char *argv[]) {
    if(argc != 2) return 0;
    yyin = fopen(argv[1], "r");
    outlog.open("22101869_log.txt", ios::trunc); 
    error_file.open("22101869_error.txt", ios::trunc); 

    table = new symbol_table(10); 
    yyparse();
    
    outlog << "Total lines: " << lines << endl;
    outlog << "Total errors: " << error_count << endl;
    error_file << "Total errors: " << error_count << endl;

    outlog.close(); 
    error_file.close();
    fclose(yyin);
    return 0;
}
