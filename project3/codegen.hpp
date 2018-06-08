#pragma once

#include <iostream>
#include <fstream>
#include <stack>
#include "symbols.hpp"

using namespace std;

extern string filename;
extern ofstream out;

enum condition{
  IFLT,
  IFGT,
  IFLE,
  IFGE,
  IFEQ,
  IFNE
};

struct Label {
  int count;
  int loop_flag;
  Label(int num);
};

class LabelManager{
  private:
    int labelCount;
  public:
    stack<Label> lStack;
    LabelManager();
    void pushNLabel(int n);
    void NLabel(int n);
    void popLabel();
    int takeLabel(int n);
    int getLable();
    int getFlag();
};

void genProgramStart();
void genProgramEnd();

void genBlockEnd();

void genGlobalVar(string id);
void genGlobalVarWithVal(string id, int val);

void genLocalVarWithVal(int idx, int val);

void genConstStr(string str);
void genConstInt(int val);

void genGetGlobalVar(string id);
void genGetLocalVar(int idx);
void genSetGlobalVar(string id);
void genSetLocalVar(int idx);

void genOperator(char op);
void genCondOp(int op);

void genMainStart();
void genFuncStart(idInfo info);
void genVoidFuncEnd();

void genPrintStart();
void genPrintStr();
void genPrintInt();
void genPrintlnStr();
void genPrintlnInt();

void genIReturn();
void genReturn();

void genCallFunc(idInfo info);

void genIfStart();
void genElse();
void genIfEnd();
void genIfElseEnd();

void genWhileStart();
void genWhileCond();
void genWhileEnd();
