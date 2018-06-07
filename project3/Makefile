all: compiler

compiler: lex.yy.cpp y.tab.cpp symbols.cpp symbols.hpp codegen.cpp codegen.hpp
	g++ y.tab.cpp symbols.cpp codegen.cpp -o compiler -ll -ly -std=c++11 -Wno-deprecated-register

lex.yy.cpp: scanner.l
	lex -o lex.yy.cpp scanner.l

y.tab.cpp: parser.y
	yacc -d parser.y -o y.tab.cpp

clean:
	rm compiler lex.yy.cpp y.tab.*
