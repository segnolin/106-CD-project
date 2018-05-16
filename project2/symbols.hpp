#include <iostream>
#include <map>
#include <vector>

using namespace std;

enum type{
  intType,
  realType,
  boolType,
  strType,
  arrayType
};

enum idFlag {
  constValueFlag,
  constVariableFlag,
  variableFlag,
  functionFlag
};

struct idValue;
struct idInfo;

struct idValue {
  int ival;
  double dval;
  bool bval;
  string sval;
  vector<idInfo> aval;
};

struct idInfo {
  int index;
  string id;
  int type;
  int flag;
  idValue value;
};

class SymbolTable {
  private:
    vector<string> symbols;
    map<string, idInfo> table_map;
    int index;
  public:
    SymbolTable();
    int insert(string id, int type, int flag, idValue value);
    idInfo *lookup(string id);
    bool isExist(string id);
};

class SymbolTableList {
  private:
    vector<SymbolTable> list;
    int top;
  public:
    SymbolTableList();
    void push();
    bool pop();
    int insert(string id, idInfo info);
    idInfo *lookup(string id);
};

/* utilities */

bool isConst(idInfo info);
idInfo *intConst(int val);
idInfo *realConst(double val);
idInfo *boolConst(bool val);
idInfo *strConst(string *val);
