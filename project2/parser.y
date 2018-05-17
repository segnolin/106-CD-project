%{

#include <iostream>
#include "symbols.hpp"
#include "lex.yy.cpp"

#define Trace(t) if (Opt_P) cout << "TRACE => " << t << endl;

int Opt_P = 1;
void yyerror(string s);

SymbolTableList symbols;

%}

/* yylval */
%union {
  int ival;
  double dval;
  bool bval;
  string *sval;
  idInfo* info;
  int type;
}

/* tokens */
%token INC DEC LE GE EQ NEQ AND OR ADD SUB MUL DIV 
%token BOOL BREAK CHAR CONTINUE DO ELSE ENUM EXTERN FLOAT FOR FN IF IN INT LET LOOP MATCH MUT PRINT PRINTLN PUB RETURN SELF STATIC STR STRUCT USE WHERE WHILE
%token <ival> INT_CONST
%token <dval> REAL_CONST
%token <bval> BOOL_CONST
%token <sval> STR_CONST
%token <sval> ID

/* type for non-terminal */
%type <info> const_value expression func_invocation
%type <type> var_type opt_ret_type

/* precedence */
%left OR
%left AND
%left '!'
%left '<' LE EQ GE '>' NEQ
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%%

/* program */
program                 : opt_var_dec opt_func_dec
                        {
                          Trace("program");

                          symbols.dump();
                          symbols.pop();
                        }
                        ;

/* zero or more variable and constant declarations */
opt_var_dec             : var_dec opt_var_dec
                        | const_dec opt_var_dec
                        | /* zero */
                        ;

/* constant declaration */
const_dec               : LET ID ':' var_type '=' expression ';'
                        {
                          Trace("constant declaration with type");

                          if (!isConst(*$6)) yyerror("expression not constant value"); /* constant check */
                          if ($4 != $6->type) yyerror("type not match"); /* type check */

                          $6->flag = constVariableFlag;
                          $6->init = true;
                          if (symbols.insert(*$2, *$6) == -1) yyerror("constant redefinition"); /* symbol check */
                        }
                        | LET ID '=' expression ';'
                        {
                          Trace("constant declaration");

                          if (!isConst(*$4)) yyerror("expression not constant value"); /* constant check */

                          $4->flag = constVariableFlag;
                          $4->init = true;
                          if (symbols.insert(*$2, *$4) == -1) yyerror("constant redefinition"); /* symbol check */
                        }
                        ;

/* variable declaration */
var_dec                 : LET MUT ID ':' var_type '=' expression ';'
                        {
                          Trace("variable declaration with type and expression");

                          if (!isConst(*$7)) yyerror("expression not constant value"); /* constant check */
                          if ($5 != $7->type) yyerror("type not match"); /* type check */

                          $7->flag = variableFlag;
                          $7->init = true;
                          if (symbols.insert(*$3, *$7) == -1) yyerror("variable redefinition"); /* symbol check */
                        }
                        | LET MUT ID ':' var_type ';'
                        {
                          Trace("variable declaration with type");

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $5;
                          info->init = false;
                          if (symbols.insert(*$3, *info) == -1) yyerror("variable redefinition"); /* symbol check */
                        }
                        | LET MUT ID '=' expression ';'
                        {
                          Trace("variable declaration with expression");

                          if (!isConst(*$5)) yyerror("expression not constant value"); /* constant check */

                          $5->flag = variableFlag;
                          $5->init = true;
                          if (symbols.insert(*$3, *$5) == -1) yyerror("variable redefinition"); /* symbol check */
                        }
                        | LET MUT ID ';'
                        {
                          Trace("variable declaration");

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = intType;
                          info->init = false;
                          if (symbols.insert(*$3, *info) == -1) yyerror("variable redefinition"); /* symbol check */
                        }
                        | LET MUT ID '[' var_type ',' expression ']' ';'
                        {
                          Trace("array declaration");
                        }
                        ;

/* variable type */
var_type                : INT
                        {
                          $$ = intType;
                        }
                        | FLOAT
                        {
                          $$ = realType;
                        }
                        | BOOL
                        {
                          $$ = boolType;
                        }
                        | STR
                        {
                          $$ = strType;
                        }
                        ;

/* one or more function declaration */
opt_func_dec            : func_dec opt_func_dec
                        | func_dec /* one */
                        ;

/* function declaration */
func_dec                : FN ID
                        {
                          idInfo *info = new idInfo();
                          info->flag = functionFlag;
                          info->init = false;
                          if (symbols.insert(*$2, *info) == -1) yyerror("function redefinition"); /* symbol check */

                          symbols.push();
                        }
                          '(' opt_args ')' opt_ret_type '{' opt_var_dec opt_statement '}'
                        {
                          Trace("function declaration");

                          symbols.dump();
                          symbols.pop();
                        }
                        ;

/* zero or more arguments */
opt_args                : args
                        | /* zero */
                        ;

/* arguments */
args                    : arg ',' args
                        | arg
                        ; 

/* argument */
arg                     : ID ':' var_type
                        {
                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $3;
                          info->init = false;
                          if (symbols.insert(*$1, *info) == -1) yyerror("variable redefinition");
                        }
                        ;

/* optional return type */
opt_ret_type            : '-' '>' var_type
                        {
                          symbols.funcReturnType($3);
                        }
                        | /* void */
                        {
                          symbols.funcReturnType(voidType);
                        }
                        ;

/* one or more statements */
opt_statement           : statement opt_statement
                        | statement /* one */
                        ;

/* statement */
statement               : simple
                        | block
                        | conditional
                        | loop
                        | func_invocation
                        ;

/* simple */
simple                  : ID '=' expression ';'
                        {
                          Trace("statement: variable assignment");
                        }
                        | ID '[' expression ']' '=' expression ';'
                        {
                          Trace("statement: array assignment");
                        }
                        | PRINT expression ';'
                        {
                          Trace("statement: print expression");
                        }
                        | PRINTLN expression ';'
                        {
                          Trace("statement: println expression");
                        }
                        | RETURN expression ';'
                        {
                          Trace("statement: return expression");
                        }
                        | RETURN ';'
                        {
                          Trace("statement: return");
                        }
                        | expression ';'
                        {
                          Trace("statement: expression");
                        }
                        ;

/* block */
block                   : '{' opt_var_dec opt_statement '}'
                        ;

/* conditional */
conditional             : IF '(' expression ')' block ELSE block
                        {
                          Trace("statement: if else");

                          if ($3->type != boolType) yyerror("condition type error");
                        }
                        | IF '(' expression ')' block
                        {
                          Trace("statement: if");

                          if ($3->type != boolType) yyerror("condition type error");
                        }
                        ;

/* loop */
loop                    : WHILE '(' expression ')' block
                        {
                          Trace("statement: while loop");

                          if ($3->type != boolType) yyerror("condition type error");
                        }
                        ;

/* function invocation */
func_invocation         : ID '(' opt_comma_separated ')'
                        {
                          Trace("statement: function invocation");
                        }
                        ;

/* optional comma-separated expressions */
opt_comma_separated     : comma_separated
                        | /* zero */
                        ;

/* comma-separated expressions */
comma_separated         : expression ',' comma_separated
                        | expression /* func_expression */
                        ;

/* constant value */
const_value             : INT_CONST
                        {
                          $$ = intConst($1);
                        }
                        | REAL_CONST
                        {
                          $$ = realConst($1);
                        }
                        | BOOL_CONST
                        {
                          $$ = boolConst($1);
                        }
                        | STR_CONST
                        {
                          $$ = strConst($1);
                        }
                        ;

/* expression */
expression              : ID
                        {
                          idInfo *info = symbols.lookup(*$1);
                          if (info == NULL) yyerror("undeclared indentifier"); /* declaration check */
                          $$ = info;
                        }
                        | const_value
                        | ID '[' expression ']'
                        | func_invocation
                        | '-' expression %prec UMINUS
                        {
                          Trace("-expression");

                          if ($2->type != intType && $2->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $2->type;
                          $$ = info;
                        }
                        | expression '*' expression
                        {
                          Trace("expression * expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $1->type;
                          $$ = info;
                        }
                        | expression '/' expression
                        {
                          Trace("expression / expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $1->type;
                          $$ = info;
                        }
                        | expression '+' expression
                        {
                          Trace("expression + expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType && $1->type != strType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $1->type;
                          $$ = info;
                        }
                        | expression '-' expression
                        {
                          Trace("expression - expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $1->type;
                          $$ = info;
                        }
                        | expression '<' expression
                        {
                          Trace("expression < expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;
                        }
                        | expression LE expression
                        {
                          Trace("expression <= expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;
                        }
                        | expression EQ expression
                        {
                          Trace("expression == expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;
                        }
                        | expression GE expression
                        {
                          Trace("expression >= expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;
                        }
                        | expression '>' expression
                        {
                          Trace("expression > expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;
                        }
                        | expression NEQ expression
                        {
                          Trace("expression != expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != intType && $1->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;
                        }
                        | '!' expression
                        {
                          Trace("!expression");

                          if ($2->type != boolType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;
                        }
                        | expression AND expression
                        {
                          Trace("expression && expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != boolType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;
                        }
                        | expression OR expression
                        {
                          Trace("expression || expression");

                          if ($1->type != $3->type) yyerror("type not match"); /* type check */
                          if ($1->type != boolType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;
                        }
                        | '(' expression ')'
                        {
                          Trace("(expression)");
                          $$ = $2;
                        }
                        ;

%%

void yyerror(string s) {
  cerr << "line " << linenum << ": " << s << endl;
  exit(1);
}

int main(void) {
  yyparse();
  return 0;
}
