all: parser

parser: lex.yy.cpp y.tab.cpp
	g++ y.tab.cpp -o parser -ll -ly

lex.yy.cpp: scanner.l
	lex -o lex.yy.cpp scanner.l

y.tab.cpp: parser.y
	yacc -d parser.y -o y.tab.cpp

clean:
	rm parser lex.yy.cpp y.tab.*
