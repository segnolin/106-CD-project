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

void genProgramStart();

void genBlockEnd();

void genGlobalVar(string id);
void genGlobalVarWithVal(string id, int val);

void genLocalVarWithVal(int idx, int val);

void genConstStr(string str);
void genConstInt(int val);

void genGetGlobalVar(string id);
void genGetLocalVar(int idx);

void genOperator(char op);
void genCondOp(int op);

void genMainStart();
void genFuncStart(idInfo info);
void genVoidFuncEnd();
