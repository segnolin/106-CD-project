all: scanner

scanner: lex.yy.c
	gcc -o scanner -O lex.yy.c -ll

lex.yy.c: scanner.l
	lex scanner.l

clean:
	rm scanner lex.yy.c
