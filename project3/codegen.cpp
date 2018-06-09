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

void LabelManager::NLabel(int n)
{
  lStack.top().count += n;
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

int LabelManager::getFlag()
{
  return lStack.top().loop_flag;
}

void genProgramStart()
{
  out << "class " << filename << endl << "{" << endl;
}

void genProgramEnd()
{
  out << "}" << endl;
}

void genBlockEnd()
{
  out << "\t}" << endl;
}

void genGlobalVar(string id)
{
  out << "\tfield static int " << id << endl;
}

void genGlobalVarWithVal(string id, int val)
{
  out << "\tfield static int " << id << " = " << val << endl;
}

void genLocalVarWithVal(int idx, int val)
{
  out << "\t\tistore " << idx << endl;
}

void genConstStr(string str)
{
  out << "\t\tldc \"" << str << "\"" << endl;
}

void genConstInt(int val)
{
  out << "\t\tsipush " << val << endl;
}

void genGetGlobalVar(string id)
{
  out << "\t\tgetstatic int " << filename << "." << id << endl;
}

void genGetLocalVar(int idx)
{
  out << "\t\tiload " << idx << endl;
}

void genSetGlobalVar(string id)
{
  out << "\t\tputstatic int " << filename << "." << id << endl;
}

void genSetLocalVar(int idx)
{
  out << "\t\tistore " << idx << endl;
}

void genOperator(char op)
{
  switch (op) {
    case 'm': out << "\t\tineg" << endl; break;
    case '*': out << "\t\timul" << endl; break;
    case '/': out << "\t\tidiv" << endl; break;
    case '+': out << "\t\tiadd" << endl; break;
    case '-': out << "\t\tisub" << endl; break;
    case '!': out << "\t\tldc 1" << endl << "\t\tixor" << endl; break;
    case '&': out << "\t\tiand" << endl; break;
    case '|': out << "\t\tior" << endl; break;
    case '%': out << "\t\tirem" << endl; break;
  }
}

void genCondOp(int op){
  cout << "2\n"; 
  out << "\t\tisub" << endl;
  int lb1 = lm.getLable();
  int lb2 = lm.getLable();
  switch (op) {
    case IFLT: out << "\t\tiflt"; break;
    case IFGT: out << "\t\tifgt"; break;
    case IFLE: out << "\t\tifle"; break;
    case IFGE: out << "\t\tifge"; break;
    case IFEQ: out << "\t\tifeq"; break;
    case IFNE: out << "\t\tifne"; break;
  }
  out << " L" << lb1 << endl;
  out << "\t\ticonst_0" << endl;
  out << "\t\tgoto L" << lb2 << endl;
  out << "L" << lb1 << ":" << endl;
  out << "\t\ticonst_1" << endl;
  out << "L" << lb2 << ":" << endl;
}

void genMainStart()
{
  out << "\tmethod public static void main(java.lang.String[])" << endl;
  out << "\tmax_stack 15" << endl;
  out << "\tmax_locals 15" << endl << "\t{" << endl;
}

void genFuncStart(idInfo info)
{
  out << "\tmethod public static ";
  out << ((info.type == voidType)? "void" : "int");
  out << " " + info.id + "(";
  for (int i = 0; i < info.value.aval.size(); i++) {
    if (i != 0) out << ", ";
    out << "int";
  }
  out << ")" << endl;
  out << "\tmax_stack 15" << endl;
  out << "\tmax_locals 15" << endl << "\t{" << endl;
  /*
  for (int i = 0; i < info.value.aval.size(); i++) {
    out << "\t\tiload " << i << endl;
  }
  */
}

void genVoidFuncEnd()
{
  out << "\t\treturn" << endl << "\t}" << endl;
}

void genPrintStart()
{
  out << "\t\tgetstatic java.io.PrintStream java.lang.System.out" << endl;
}

void genPrintStr()
{
  out << "\t\tinvokevirtual void java.io.PrintStream.print(java.lang.String)" << endl;
}

void genPrintInt()
{
  out << "\t\tinvokevirtual void java.io.PrintStream.print(int)" << endl;
}

void genPrintlnStr()
{
  out << "\t\tinvokevirtual void java.io.PrintStream.println(java.lang.String)" << endl;
}

void genPrintlnInt()
{
  out << "\t\tinvokevirtual void java.io.PrintStream.println(int)" << endl;
}

void genIReturn()
{
  out << "\t\tireturn" << endl;
}

void genReturn()
{
  out << "\t\treturn" << endl;
}

void genCallFunc(idInfo info)
{
  out << "\t\tinvokestatic ";
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
  out << "\t\tifeq L" << lm.takeLabel(0) << endl;
}

void genElse()
{
  out << "\t\tgoto L" << lm.takeLabel(1) << endl;
  out << "L" << lm.takeLabel(0) << ":" << endl;
}

void genIfEnd()
{
  out << "L" << lm.takeLabel(0) << ":" << endl;
  lm.popLabel();
}

void genIfElseEnd()
{
  out << "L" << lm.takeLabel(1) << ":" << endl;
  lm.popLabel();
}

void genWhileStart()
{
  cout << "1\n"; 
  lm.pushNLabel(1);
  out << "L" << lm.takeLabel(0) << ":" << endl;
}

void genWhileCond()
{
  cout << "3\n";
  lm.NLabel(1);
  out << "\t\tifeq L" << lm.takeLabel(3 + lm.getFlag()) << endl;
}

void genWhileEnd()
{
  out << "\t\tgoto L" << lm.takeLabel(lm.getFlag()) << endl;
  out << "L" << lm.takeLabel(3 + lm.getFlag()) << ":" << endl;
  lm.popLabel();
}
