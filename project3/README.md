# 106-CD-project3

## Building

Run `Makefile`

```
make
```

Or, compile it manually

```
lex -o lex.yy.cpp scanner.l
yacc -d parser.y -o y.tab.cpp
g++ y.tab.cpp symbols.cpp codegen.cpp -o compiler -ll -ly -std=c++11 -Wno-deprecated-register
```

## Usage

Running `example.rust` in JVM

```
make run file=example
```

Or, run it manually

```
./compiler example.rust
./javaa example.jasm
java example
```

## Change

### parser.l

- add #include "codegen.hpp" header file
- add option flags (`Opt_D`) to determine whether to dump the symbol table.
- set `yyin` to input file stream.
- add output file stream.
- add code generation functions to create java assembly.

### symbols.hpp / symbols.cpp

- add `isGlobal` to determine the scope of variable.
- add `getIndex` to get variable index.
- add `getValue` to get integer and boolean value.

### new files
- codegen.hpp / codegen.cpp for generating java assembly.
