#pragma once

#include <iostream>
#include <fstream>
#include <stack>
#include "symbols.hpp"

using namespace std;

extern string filename;
extern ofstream out;

void genProgramStart();
void genProgramEnd();

void genGlobalVar(string id);
void genGlobalVarWithVal(string id, int val);

void genLocalVarWithVal(int idx, int val);
