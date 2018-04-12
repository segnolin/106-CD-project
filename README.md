# 106-CD-project1

## Building

Run `Makefile`

```
make
```

Or, compile manually

```
lex scanner.l
mv lex.yy.c lex.yy.cc
g++ -o scanner -O lex.yy.cc -ll
```

## Usage

Set example rust file as stdin

```
./scanner < example.rust 
```

The output would be:

```
1: /*
2:  * Example with Functions
3:  */
4: 
5: // variables
<LET>
<MUT>
<IDENTIFIER: c>
<';'>
6: let mut c;
<LET>
<MUT>
<IDENTIFIER: a>
<'='>
<INTEGER: 5>
<';'>
7: let mut a = 5;
8:     
9: // function declaration
<FN>
<IDENTIFIER: add>
<'('>
<IDENTIFIER: a>
<':'>
<INT>
<','>
<IDENTIFIER: b>
<':'>
<INT>
<')'>
<'-'>
<'>'>
<INT>
10: fn add(a:int, b:int) -> int
<'{'>
11: {
<RETURN>
<IDENTIFIER: a>
<'+'>
<IDENTIFIER: b>
<';'>
12:   return a+b;
<'}'>
13: }
14:     
15: // main function
<FN>
<IDENTIFIER: main>
<'('>
<')'>
16: fn main() 
<'{'>
17: {
<IDENTIFIER: c>
<'='>
<IDENTIFIER: add>
<'('>
<IDENTIFIER: a>
<','>
<INTEGER: 10>
<')'>
<';'>
18:   c = add(a, 10);
<IF>
<'('>
<IDENTIFIER: c>
<'>'>
<INTEGER: 10>
<')'>
<'{'>
19:   if (c > 10) {
<PRINT>
<'-'>
<IDENTIFIER: c>
<';'>
20:     print -c;
<'}'>
21:   }
<ELSE>
<'{'>
22:   else {
<PRINT>
<IDENTIFIER: c>
<';'>
23:     print c;
<'}'>
24:   }
<PRINTLN>
<'('>
<STRING: Hello World>
<')'>
<';'>
25:   println ("Hello World");
<'}'>
26: }

Symbol Table:
0:	c
1:	a
2:	add
3:	b
4:	main
```
