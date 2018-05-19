# 106-CD-project2

## Building

Run `Makefile`

```
make
```

Or, compile manually

```
lex -o lex.yy.cpp scanner.l
yacc -d parser.y -o y.tab.cpp
g++ y.tab.cpp symbols.cpp -o parser -ll -ly -std=c++11 -Wno-deprecated-register
```

## Usage

Set example rust file as stdin

```
./parser < example.rust 
```

## Change

### scanner.l

- add `#include "y.tab.hpp"` header file
- add option flags (`Opt_T` `Opt_S`) to determine whether to print token and source code
- add retrun token to yacc
- remove symbol table from source and separate it into files (`symbols.cpp` `symbols.hpp`)
