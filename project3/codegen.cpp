#include "codegen.hpp"

void genProgramStart()
{
  out << "class " << filename << endl << "{" << endl;
}

void genProgramEnd()
{
  out << "}" << endl;
}

void genGlobalVar(string id)
{
  out << "field static int " << id << endl;
}

void genGlobalVarWithVal(string id, int val)
{
  out << "field static int " << id << " = " << val << endl;
}

void genLocalVarWithVal(int idx, int val)
{
  out << "ldc " << val << endl << "istore " << idx << endl;
}
