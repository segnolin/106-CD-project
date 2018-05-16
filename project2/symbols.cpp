#include "symbols.hpp"

SymbolTable::SymbolTable()
{
  index = 0;
}

int SymbolTable::insert(string id, int type, int flag, idValue value)
{
  if (table_map.find(id) != table_map.end()) {
    return -1;
  }
  else {
    symbols.push_back(id);
    table_map[id].index = index;
    table_map[id].id = id;
    table_map[id].type = type;
    table_map[id].flag = flag;
    table_map[id].value = value;
    return index++;
  }
}

idInfo *SymbolTable::lookup(string id)
{
  if (isExist(id)) return new idInfo(table_map[id]);
	else return NULL;
}

bool SymbolTable::isExist(string id)
{
  return table_map.find(id) != table_map.end();
}

SymbolTableList::SymbolTableList()
{
  top = -1;
  push();
}

void SymbolTableList::push()
{
  list.push_back(SymbolTable());
  ++top;
}

bool SymbolTableList::pop()
{
  if (list.size() <= 0) return false;
  list.pop_back();
  --top;
  return true;
}

int SymbolTableList::insert(string id, idInfo info)
{
  return list[top].insert(id, info.type, info.flag, info.value);
}

idInfo *SymbolTableList::lookup(string id)
{
  for (int i = top; i >= 0; --i) {
    if (list[i].isExist(id)) return list[i].lookup(id);
  }
  return NULL;
}

/* utilities */

bool isConst(idInfo info)
{
  if (info.flag == constValueFlag || info.flag == constVariableFlag) return true;
  else return false;
}

idInfo *intConst(int val)
{
  idInfo* info = new idInfo();
  info->index = 0;
  info->type = intType;
  info->value.ival = val;
  info->flag = constValueFlag;
  return info;
}

idInfo *realConst(double val)
{
  idInfo* info = new idInfo();
  info->index = 0;
  info->type = realType;
  info->value.dval = val;
  info->flag = constValueFlag;
  return info;
}

idInfo *boolConst(bool val)
{
  idInfo* info = new idInfo();
  info->index = 0;
  info->type = boolType;
  info->value.bval = val;
  info->flag = constValueFlag;
  return info;
}

idInfo *strConst(string *val)
{
  idInfo* info = new idInfo();
  info->index = 0;
  info->type = strType;
  info->value.sval = *val;
  info->flag = constValueFlag;
  return info;
}
