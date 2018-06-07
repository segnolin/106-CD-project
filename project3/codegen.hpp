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
