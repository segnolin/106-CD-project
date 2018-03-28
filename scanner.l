%{

#define MAX_LINE_LENG 256
#define LIST strcat(buf, yytext)
#define token(t) { LIST; printf("<'%s'>\n", #t); }
#define tokenChar(t) { LIST; printf("<'%c'>\n", t); }
#define tokenInteger(t,i) { LIST; printf("<%s: %d>\n", #t, i); }
#define tokenReal(t,f) { LIST; printf("<%s: %lf>\n", #t, f); }
#define tokenString(t,s) { LIST; printf("<%s: %s>\n", #t, s); }

int linenum = 0;
char buf[MAX_LINE_LENG];

%}

DELIMITER           ([,:;()[\]{}])
ARITHMETIC          ([-+*/%])
RELATIONAL          ([<>!=])
IDENTIFIER          ([A-Za-z_][0-9A-Za-z_]*)
DIGIT               ([0-9]+)
INTEGER             ([-+]?{DIGIT})
REAL                ([-+]?{DIGIT}\.{DIGIT}?([Ee](-+)?{DIGIT})?)
STRING              (\"(\"\"|[^"\n])*\")

%%

 /* single character token */
{DELIMITER}  |
{ARITHMETIC} |
{RELATIONAL}        { tokenChar(yytext[0]); }

 /* two-character token */
"++"                { token(++); }
"--"                { token(--); }
"<="                { token(<=); }
">="                { token(>=); }
"=="                { token(==); }
"!="                { token(!=); }
"&&"                { token(&&); }
"||"                { token(||); }
"+="                { token(+=); }
"-="                { token(-=); }
"*="                { token(*=); }
"/="                { token(/=); }

 /* keyword */
"bool"              { token(BOOL); }
"break"             { token(BREAK); }
"char"              { token(CHAR); }
"continue"          { token(CONTINUE); }
"do"                { token(DO); }
"else"              { token(ELSE); }
"enum"              { token(ENUM); }
"extern"            { token(EXTERN); }
"false"             { token(FALSE); }
"float"             { token(FLOAT); }
"for"               { token(FOR); }
"fn"                { token(FN); }
"if"                { token(IF); }
"in"                { token(IN); }
"int"               { token(INT); }
"let"               { token(LET); }
"loop"              { token(LOOP); }
"match"             { token(MATCH); }
"mut"               { token(MUT); }
"print"             { token(PRINT); }
"println"           { token(PRINTLN); }
"pub"               { token(PUB); }
"return"            { token(RETURN); }
"self"              { token(SELF); }
"static"            { token(STATIC); }
"str"               { token(STR); }
"struct"            { token(STRUCT); }
"true"              { token(TRUE); }
"use"               { token(USE); }
"where"             { token(WHERE); }
"while"             { token(WHILE); }

{IDENTIFIER}        {
                      tokenString(IDENTIFIER, yytext);
                      //push to symbol table
                    }

{INTEGER}           {
                      tokenInteger(INTEGER, atoi(yytext));
                    }

{REAL}              {
                      tokenReal(REAL, atof(yytext));
                    }

{STRING}            {
                      char s[MAX_LINE_LENG] = {0};
                      int idx = 0;
                      for (int i = 1; i < yyleng - 1; ++i) {
                        if (yytext[i] == '"') ++i;
                        s[idx++] = yytext[i];
                      }
                      tokenString(STRING, s);
                    }

\n                  {
                      LIST;
                      printf("%d: %s", linenum, buf);
                      linenum++;
                      buf[0] = '\0';
                    }

[ \t]*              { LIST; }

.                   {
                      LIST;
                      printf("%d:%s\n", linenum, buf);
                      printf("bad character:'%s'\n",yytext);
                      exit(-1);
                    }

%%
