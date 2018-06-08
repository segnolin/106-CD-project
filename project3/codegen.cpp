#include "codegen.hpp"

LabelManager lm;

Label::Label(int num)
{
  count = num;
  loop_flag = -1;
}

LabelManager::LabelManager()
{
  labelCount = 0;
}

void LabelManager::pushNLabel(int n)
{
  lStack.push(Label(labelCount));
  labelCount += n;
}

void LabelManager::popLabel()
{
  lStack.pop();
}

int LabelManager::takeLabel(int n)
{
  return lStack.top().count + n;
}

int LabelManager::getLable()
{
  return labelCount++;
}

void LabelManager::addFlag()
{
  lStack.top().loop_flag += 1;
}

int LabelManager::getFlag()
{
  return lStack.top().loop_flag;
}

void genProgramStart()
{
  out << "class " << filename << endl << "{" << endl;
}

void genBlockEnd()
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

void genConstStr(string str)
{
  out << "ldc \"" << str << "\"" << endl;
}

void genConstInt(int val)
{
  out << "ldc " << val << endl;
}

void genGetGlobalVar(string id)
{
  out << "getstatic int " << filename << "." << id << endl;
}

void genGetLocalVar(int idx)
{
  out << "iload " << idx << endl;
}

void genSetGlobalVar(string id)
{
  out << "putstatic int " << filename << "." << id << endl;
}

void genSetLocalVar(int idx)
{
  out << "istore " << idx << endl;
}

void genOperator(char op)
{
  switch (op) {
    case 'm': out << "ineg" << endl; break;
    case '*': out << "imul" << endl; break;
    case '/': out << "idiv" << endl; break;
    case '+': out << "iadd" << endl; break;
    case '-': out << "isub" << endl; break;
    case '!': out << "ldc 1" << endl << "ixor" << endl; break;
    case '&': out << "iand" << endl; break;
    case '|': out << "ior" << endl; break;
    case '%': out << "irem" << endl; break; //not yet implemented
  }
}

void genCondOp(int op){
  out << "isub" << endl;
  int lb1 = lm.getLable();
  int lb2 = lm.getLable();
  switch (op) {
    case IFLT: out << "iflt"; break;
    case IFGT: out << "ifgt"; break;
    case IFLE: out << "ifle"; break;
    case IFGE: out << "ifge"; break;
    case IFEQ: out << "ifeq"; break;
    case IFNE: out << "ifne"; break;
  }
  out << " L" << lb1 << endl;
  out << "iconst_0" << endl;
  out << "goto L" << lb2 << endl;
  out << "nop" << endl << "L" << lb1 << ":" << endl;
  out << "iconst_1" << endl;
  out << "nop" << endl << "L" << lb2 << ":" << endl;
}

void genMainStart()
{
  out << "method public static void main(java.lang.String[])" << endl;
  out << "max_stack 15" << endl;
  out << "max_locals 15" << endl << "{" << endl;
}

void genFuncStart(idInfo info)
{
  out << "method public static ";
  out << ((info.type == voidType)? "void" : "int");
  out << " " + info.id + "(";
  for (int i = 0; i < info.value.aval.size(); i++) {
    if (i != 0) out << ", ";
    out << "int";
  }
  out << ")" << endl;
  out << "max_stack 15" << endl;
  out << "max_locals 15" << endl << "{" << endl;
  for (int i = 0; i < info.value.aval.size(); i++) {
    out << "iload " << i << endl;
  }
}

void genVoidFuncEnd()
{
  out << "return" << endl << "}" << endl;
}

void genPrintStart()
{
  out << "getstatic java.io.PrintStream java.lang.System.out" << endl;
}

void genPrintStr()
{
  out << "invokevirtual void java.io.PrintStream.print(java.lang.String)" << endl;
}

void genPrintInt()
{
  out << "invokevirtual void java.io.PrintStream.print(int)" << endl;
}

void genPrintlnStr()
{
  out << "invokevirtual void java.io.PrintStream.println(java.lang.String)" << endl;
}

void genPrintlnInt()
{
  out << "invokevirtual void java.io.PrintStream.println(int)" << endl;
}

void genIReturn()
{
  out << "ireturn" << endl;
}

void genReturn()
{
  out << "return" << endl;
}

void genCallFunc(idInfo info)
{
  out << "invokestatic ";
  out << ((info.type == voidType)? "void" : "int");
  out << " " + filename + "." + info.id + "(";
  for (int i = 0; i < info.value.aval.size(); ++i) {
    if (i != 0) out << ", ";
    out << "int";
  }
  out << ")" << endl;
}

void genIfStart()
{
  lm.pushNLabel(2);
  out << "ifeq L" << lm.takeLabel(0) << endl;
}

void genElse()
{
  out << "goto L" << lm.takeLabel(1) << endl;
  out << "nop" << endl << "L" << lm.takeLabel(0) << ":" << endl;
}

void genIfEnd()
{
  out << "nop" << endl << "L" << lm.takeLabel(0) << ":" << endl;
  lm.popLabel();
}

void genIfElseEnd()
{
  out << "nop" << endl << "L" << lm.takeLabel(1) << ":" << endl;
  lm.popLabel();
}
