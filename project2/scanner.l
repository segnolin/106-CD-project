%{

#include "y.tab.hpp"

#define MAX_LINE_LENG 256
#define LIST strcat(buf, yytext)
#define token(t) { LIST; if(Opt_T) printf("<%s>\n", #t); }
#define tokenChar(t) { LIST; if(Opt_T) printf("<'%c'>\n", t); }
#define tokenInteger(t,i) { LIST; if(Opt_T) printf("<%s: %d>\n", #t, i); }
#define tokenString(t,s) { LIST; if(Opt_T) printf("<%s: %s>\n", #t, s); }

using namespace std;

int Opt_T = 0;
int Opt_S = 0;
int linenum = 1;
char buf[MAX_LINE_LENG];

%}

DELIMITER               ([,:;()[\]{}])
ARITHMETIC              ([-+*/%])
RELATIONAL              ([<>!=])
IDENTIFIER              ([A-Za-z_][0-9A-Za-z_]*)
DIGIT                   ([0-9]+)
INTEGER                 ([-+]?{DIGIT})
REAL                    ([-+]?{DIGIT}\.{DIGIT}?([Ee](-+)?{DIGIT})?)
STRING                  (\"(\"\"|[^"\n])*\")
SINGLE_COMMENT          (\/\/[^\n]*)
BEGIN_COMMENT           (\/\*)
END_COMMENT             (\*\/)

%x COMMENT

%%

 /* single character token */
{DELIMITER}  |
{ARITHMETIC} |
{RELATIONAL}            { tokenChar(yytext[0]); return yytext[0]; }

 /* two-character token */
"++"                    { token('++'); return INC; }
"--"                    { token('--'); return DEC; }
"<="                    { token('<='); return LE; }
">="                    { token('>='); return GE; }
"=="                    { token('=='); return EQ; }
"!="                    { token('!='); return NEQ; }
"&&"                    { token('&&'); return AND; }
"||"                    { token('||'); return OR; }
"+="                    { token('+='); return ADD; }
"-="                    { token('-='); return SUB; }
"*="                    { token('*='); return MUL; }
"/="                    { token('/='); return DIV; }

 /* keyword */
"bool"                  { token(BOOL); return BOOL; }
"break"                 { token(BREAK); return BREAK; }
"char"                  { token(CHAR); return CHAR; }
"continue"              { token(CONTINUE); return CONTINUE; }
"do"                    { token(DO); return DO; }
"else"                  { token(ELSE); return ELSE; }
"enum"                  { token(ENUM); return ENUM; }
"extern"                { token(EXTERN); return EXTERN; }
"float"                 { token(FLOAT); return FLOAT; }
"for"                   { token(FOR); return FOR; }
"fn"                    { token(FN); return FN; }
"if"                    { token(IF); return IF; }
"in"                    { token(IN); return IN; }
"int"                   { token(INT); return INT; }
"let"                   { token(LET); return LET; }
"loop"                  { token(LOOP); return LOOP; }
"match"                 { token(MATCH); return MATCH; }
"mut"                   { token(MUT); return MUT; }
"print"                 { token(PRINT); return PRINT; }
"println"               { token(PRINTLN); return PRINTLN; }
"pub"                   { token(PUB); return PUB; }
"return"                { token(RETURN); return RETURN; }
"self"                  { token(SELF); return SELF; }
"static"                { token(STATIC); return STATIC; }
"str"                   { token(STR); return STR; }
"struct"                { token(STRUCT); return STRUCT; }
"use"                   { token(USE); return USE; }
"where"                 { token(WHERE); return WHERE; }
"while"                 { token(WHILE); return WHILE; }

"false"                 { token(FALSE);
                          yylval.bval = false;
                          return BOOL_CONST;
                        }
"true"                  { token(TRUE);
                          yylval.bval = true;
                          return BOOL_CONST;
                        }

{IDENTIFIER}            {
                          tokenString(IDENTIFIER, yytext);
                          yylval.sval = new string(yytext);
                          return ID;
                        }

{INTEGER}               {
                          tokenInteger(INTEGER, atoi(yytext));
                          yylval.ival = atoi(yytext);
                          return INT_CONST;
                        }

{REAL}                  {
                          tokenString(REAL, yytext);
                          yylval.dval = atof(yytext);
                          return REAL_CONST;
                        }

{STRING}                {
                          char s[MAX_LINE_LENG] = {0};
                          int idx = 0;
                          for (int i = 1; i < yyleng - 1; ++i) {
                            if (yytext[i] == '"') ++i;
                            s[idx++] = yytext[i];
                          }
                          tokenString(STRING, s);
                          yylval.sval = new string(s);
                          return STR_CONST;
                        }

  /* comment */
{SINGLE_COMMENT}        { LIST; }

{BEGIN_COMMENT}         {
                          LIST;
                          BEGIN COMMENT;
                        }

<COMMENT>[^\n]          {
                          LIST;
                        }

<COMMENT>\n             {
                          LIST;
                          if(Opt_S) printf("%d: %s", linenum, buf);
                          linenum++;
                          buf[0] = '\0';
                        }

<COMMENT>{END_COMMENT}  {
                          LIST;
                          BEGIN INITIAL;
                        }

\n                      {
                          LIST;
                          if(Opt_S) printf("%d: %s", linenum, buf);
                          linenum++;
                          buf[0] = '\0';
                        }

[ \t]*                  { LIST; }

.                       {
                          LIST;
                          printf("%d:%s\n", linenum, buf);
                          printf("bad character:'%s'\n",yytext);
                          exit(-1);
                        }

%%
