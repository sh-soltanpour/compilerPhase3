grammar AtalkPass2;
@members {
	void print(String str){
      System.out.println(str);
  }
	 void beginScope() {
      SymbolTable.push();
  }
  void endScope(){
    SymbolTable.pop();
  }
} 
program: { beginScope();} (actor | NL)* {endScope();};

actor:
	{beginScope();}'actor' ID '<' CONST_NUM '>' NL (state | receiver | NL)* 'end' {endScope();}(
		NL
		| EOF
	);

state: type ID (',' ID)* NL;

receiver:
{beginScope();}	'receiver' ID '(' (type ID (',' type ID)*)? ')' NL statements 'end' NL{endScope();};

type: 'char' ('[' CONST_NUM ']')* | 'int' ('[' CONST_NUM ']')*;

block: {beginScope();}'begin' NL statements 'end' NL {endScope();};

statements: (statement | NL)*;

statement:
	stm_vardef
	| stm_assignment
	| stm_foreach
	| stm_if_elseif_else
	| stm_quit
	| stm_break
	| stm_tell
	| stm_write
	| block;

stm_vardef:
	type ID { SymbolTable.define(); } ('=' expr)? (',' ID { SymbolTable.define(); } ('=' expr)?)* NL ;

stm_tell:
	(ID | 'sender' | 'self') '<<' ID '(' (expr (',' expr)*)? ')' NL;

stm_write: 'write' '(' expr ')' NL;

stm_if_elseif_else:
	'if' expr NL statements ('elseif' expr NL statements)* (
		'else' NL statements
	)? 'end' NL;

stm_foreach: 'foreach' ID 'in' expr NL statements 'end' NL;

stm_quit: 'quit' NL;

stm_break: 'break' NL;

stm_assignment: expr NL;

expr: expr_assign;

expr_assign: expr_or '=' expr_assign | expr_or;

expr_or: expr_and expr_or_tmp;

expr_or_tmp: 'or' expr_and expr_or_tmp |;

expr_and: expr_eq expr_and_tmp;

expr_and_tmp: 'and' expr_eq expr_and_tmp |;

expr_eq: expr_cmp expr_eq_tmp;

expr_eq_tmp: ('==' | '<>') expr_cmp expr_eq_tmp |;

expr_cmp: expr_add expr_cmp_tmp;

expr_cmp_tmp: ('<' | '>') expr_add expr_cmp_tmp |;

expr_add: expr_mult expr_add_tmp;

expr_add_tmp: ('+' | '-') expr_mult expr_add_tmp |;

expr_mult: expr_un expr_mult_tmp;

expr_mult_tmp: ('*' | '/') expr_un expr_mult_tmp |;

expr_un: ('not' | '-') expr_un | expr_mem;

expr_mem: expr_other expr_mem_tmp;

expr_mem_tmp: '[' expr ']' expr_mem_tmp |;

expr_other:
	CONST_NUM
	| CONST_CHAR
	| CONST_STR
	| id=ID
  { 
            SymbolTableItem item = SymbolTable.top.get($id.text);
            if(item == null) {
								
                print($id.line + ") Item " + $id.text + " doesn't exist.");
            }
            else {
                SymbolTableVariableItemBase var = (SymbolTableVariableItemBase) item;
                print($id.line + ") Variable " + $id.text + " used.\t\t" +   "Base Reg: " + var.getBaseRegister() + ", Offset: " + var.getOffset());
            }
  } 
	| '{' expr (',' expr)* '}'
	| 'read' '(' CONST_NUM ')'
	| '(' expr ')';

CONST_NUM: [0-9]+;

CONST_CHAR: '\'' . '\'';

CONST_STR: '"' ~('\r' | '\n' | '"')* '"';

NL: '\r'? '\n' { setText("new_line"); };

ID: [a-zA-Z_][a-zA-Z0-9_]*;

COMMENT: '#' (~[\r\n])* -> skip;

WS: [ \t] -> skip;