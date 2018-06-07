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
