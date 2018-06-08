%{

#include <iostream>
#include "symbols.hpp"
#include "codegen.hpp"
#include "lex.yy.cpp"

#define Trace(t) if (Opt_P) cout << "TRACE => " << t << endl;

int Opt_P = 0;
int Opt_D = 0;
void yyerror(string s);

SymbolTableList symbols;
vector<vector<idInfo> > functions;

string filename;
ofstream out;

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
program                 :
                        {
                          genProgramStart();
                        }
                          opt_var_dec opt_func_dec
                        {
                          Trace("program");

                          if (Opt_D) symbols.dump();
                          symbols.pop();

                          genBlockEnd();
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

                          if ($5 == intType || $5 == boolType) {
                            int idx = symbols.getIndex(*$3);
                            int val = getValue(*$7);
                            if (idx == -1) {
                              genGlobalVarWithVal(*$3, val);
                            } 
                            else if (idx >= 0) {
                              genLocalVarWithVal(idx, val);
                            }
                          }
                        }
                        | LET MUT ID ':' var_type ';'
                        {
                          Trace("variable declaration with type");

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $5;
                          info->init = false;
                          if (symbols.insert(*$3, *info) == -1) yyerror("variable redefinition"); /* symbol check */

                          if ($5 == intType || $5 == boolType) {
                            int idx = symbols.getIndex(*$3);
                            if (idx == -1) {
                              genGlobalVar(*$3);
                            } 
                          }
                        }
                        | LET MUT ID '=' expression ';'
                        {
                          Trace("variable declaration with expression");

                          if (!isConst(*$5)) yyerror("expression not constant value"); /* constant check */

                          $5->flag = variableFlag;
                          $5->init = true;
                          if (symbols.insert(*$3, *$5) == -1) yyerror("variable redefinition"); /* symbol check */

                          int idx = symbols.getIndex(*$3);
                          int val = getValue(*$5);
                          if (idx == -1) {
                            genGlobalVarWithVal(*$3, val);
                          } 
                          else if (idx >= 0) {
                            genLocalVarWithVal(idx, val);
                          }
                        }
                        | LET MUT ID ';'
                        {
                          Trace("variable declaration");

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = intType;
                          info->init = false;
                          if (symbols.insert(*$3, *info) == -1) yyerror("variable redefinition"); /* symbol check */

                          int idx = symbols.getIndex(*$3);
                          if (idx == -1) {
                            genGlobalVar(*$3);
                          } 
                        }
                        | LET MUT ID '[' var_type ',' expression ']' ';'
                        {
                          Trace("array declaration");

                          if (!isConst(*$7)) yyerror("array size not constant");
                          if ($7->type != intType) yyerror("array size not integer");
                          if ($7->value.ival < 1) yyerror("array size < 1");
                          if (symbols.insert(*$3, $5, $7->value.ival) == -1) yyerror("variable redefinition");
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
                          '(' opt_args ')' opt_ret_type '{'
                        {
                          if (*$2 == "main") {
                            genMainStart();
                          }
                          else {
                            genFuncStart(*symbols.lookup(*$2));
                          }
                        }
                          opt_var_dec opt_statement '}'
                        {
                          Trace("function declaration");

                          if (symbols.lookup(*$2)->type == voidType) {
                            genVoidFuncEnd();
                          }
                          else {
                            genBlockEnd();
                          }

                          if (Opt_D) symbols.dump();
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
                          symbols.addFuncArg(*$1, *info);
                        }
                        ;

/* optional return type */
opt_ret_type            : '-' '>' var_type
                        {
                          symbols.setFuncType($3);
                        }
                        | /* void */
                        {
                          symbols.setFuncType(voidType);
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

                          idInfo *info = symbols.lookup(*$1);
                          if (info == NULL) yyerror("undeclared indentifier"); /* declaration check */
                          if (info->flag == constVariableFlag) yyerror("can't assign to constant"); /* constant check */
                          if (info->flag == functionFlag) yyerror("can't assign to function"); /* function check */
                          if (info->type != $3->type) yyerror("type not match"); /* type check */

                          if (info->type == intType || info->type == boolType) {
                            int idx = symbols.getIndex(*$1);
                            if (idx == -1) genSetGlobalVar(*$1);
                            else genSetLocalVar(idx);
                          }
                        }
                        | ID '[' expression ']' '=' expression ';'
                        {
                          Trace("statement: array assignment");

                          idInfo *info = symbols.lookup(*$1);
                          if (info == NULL) yyerror("undeclared indentifier"); /* declaration check */
                          if (info->flag != variableFlag) yyerror("not a variable"); /* variable check */
                          if (info->type != arrayType) yyerror("not a array"); /* type check */
                          if ($3->type != intType) yyerror("index not integer"); /* index type check */
                          if ($3->value.ival >= info->value.aval.size() || $3->value.ival < 0) yyerror("index out of range"); /* index range check */
                          if (info->value.aval[0].type != $6->type) yyerror("type not match"); /* type check */
                        }
                        |
                        {
                          genPrintStart();
                        }
                          PRINT expression ';'
                        {
                          Trace("statement: print expression");
                          if ($3->type == strType) genPrintStr();
                          else genPrintInt();
                        }
                        |
                        {
                          genPrintStart();
                        }
                          PRINTLN expression ';'
                        {
                          Trace("statement: println expression");
                          if ($3->type == strType) genPrintlnStr();
                          else genPrintlnInt();
                        }
                        | RETURN expression ';'
                        {
                          Trace("statement: return expression");
                          genIReturn();
                        }
                        | RETURN ';'
                        {
                          Trace("statement: return");
                          genReturn();
                        }
                        | expression ';'
                        {
                          Trace("statement: expression");
                        }
                        ;

/* block */
block                   : '{'
                        {
                          symbols.push();
                        }
                          opt_var_dec opt_statement
                          '}'
                        {
                          if (Opt_D) symbols.dump();
                          symbols.pop();
                        }
                        ;

/* conditional */
conditional             : IF '(' expression ')' ifStart block ELSE
                        {
                          genElse();
                        }
                          block
                        {
                          Trace("statement: if else");

                          if ($3->type != boolType) yyerror("condition type error");
                          genIfElseEnd();
                        }
                        | IF '(' expression ')' ifStart block
                        {
                          Trace("statement: if");

                          if ($3->type != boolType) yyerror("condition type error");
                          genIfEnd();
                        }
                        ;

ifStart                 :
                        {
                          genIfStart();
                        }

/* loop */
loop                    : WHILE '('
                        {
                          genWhileStart();
                        }
                          expression
                        {
                          genWhileCond();
                        }
                          ')' block
                        {
                          Trace("statement: while loop");

                          genWhileEnd();
                        }
                        ;

/* function invocation */
func_invocation         : ID
                        {
                          functions.push_back(vector<idInfo>());
                        }
                          '(' opt_comma_separated ')'
                        {
                          Trace("statement: function invocation");

                          idInfo *info = symbols.lookup(*$1);
                          if (info == NULL) yyerror("undeclared indentifier"); /* declaration check */
                          if (info->flag != functionFlag) yyerror("not a function"); /* function check */

                          vector<idInfo> para = info->value.aval;
                          if (para.size() != functions[functions.size() - 1].size()) yyerror("parameter size not match"); /* parameter size check */

                          for (int i = 0; i < para.size(); ++i) {
                            if (para[i].type != functions[functions.size() - 1].at(i).type) yyerror("parameter type not match"); /* parameter type check */
                          }

                          genCallFunc(*info);

                          $$ = info;
                          functions.pop_back();
                        }
                        ;

/* optional comma-separated expressions */
opt_comma_separated     : comma_separated
                        | /* zero */
                        ;

/* comma-separated expressions */
comma_separated         : func_expression ',' comma_separated
                        | func_expression /* func_expression */
                        ;

/* function expression */
func_expression         : expression
                        {
                          functions[functions.size() - 1].push_back(*$1);
                        }

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

                          if (!symbols.isGlobal() && isConst(*info)) {
                            if (info->type == strType) genConstStr(info->value.sval);
                            else if (info->type == intType || info->type == boolType) genConstInt(getValue(*info));
                          }
                          else if (info->type == intType || info->type == boolType) {
                            int idx = symbols.getIndex(*$1);
                            if (idx == -1) genGetGlobalVar(*$1);
                            else genGetLocalVar(idx);
                          }
                        }
                        | const_value
                        {
                          if (!symbols.isGlobal()) {
                            if ($1->type == strType) genConstStr($1->value.sval);
                            else if ($1->type == intType || $1->type == boolType) genConstInt(getValue(*$1));
                          }
                        }
                        | ID '[' expression ']'
                        {
                          idInfo *info = symbols.lookup(*$1);
                          if (info == NULL) yyerror("undeclared identifier");
                          if (info->type != arrayType) yyerror("not array type");
                          if ($3->type != intType) yyerror("invalid index");
                          if ($3->value.ival >= info->value.aval.size()) yyerror("index out of range");
                          $$ = new idInfo(info->value.aval[$3->value.ival]);
                        }
                        | func_invocation
                        | '-' expression %prec UMINUS
                        {
                          Trace("-expression");

                          if ($2->type != intType && $2->type != realType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = $2->type;
                          $$ = info;

                          if ($2->type == intType) genOperator('m');
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

                          if ($1->type == intType) genOperator('*');
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

                          if ($1->type == intType) genOperator('/');
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

                          if ($1->type == intType) genOperator('+');
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

                          if ($1->type == intType) genOperator('-');
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

                          if ($1->type == intType) genCondOp(IFLT);
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

                          if ($1->type == intType) genCondOp(IFLE);
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

                          if ($1->type == intType || $1->type == boolType) genCondOp(IFEQ);
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

                          if ($1->type == intType) genCondOp(IFGE);
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

                          if ($1->type == intType) genCondOp(IFGT);
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

                          if ($1->type == intType || $1->type == boolType) genCondOp(IFNE);
                        }
                        | '!' expression
                        {
                          Trace("!expression");

                          if ($2->type != boolType) yyerror("operator error"); /* operator check */

                          idInfo *info = new idInfo();
                          info->flag = variableFlag;
                          info->type = boolType;
                          $$ = info;

                          if ($2->type == boolType) genOperator('!');
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

                          if ($1->type == boolType) genOperator('&');
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

                          if ($1->type == boolType) genOperator('|');
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

int main(int argc, char **argv) {
  yyin = fopen(argv[1], "r");
  string source = string(argv[1]);
  int dot = source.find(".");
  filename = source.substr(0, dot);
  out.open(filename + ".jasm");

  yyparse();
  return 0;
}
