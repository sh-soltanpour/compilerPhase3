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

expr returns [Type return_type]: expr_assign{$return_type = $expr_assign.return_type;};

expr_assign returns [Type return_type]: expr_or '=' expr_assign{$return_type = Tools.expr_assign_typeCheck($expr_or.return_type , $expr_assign.return_type);} | expr_or{$return_type = $expr_or.return_type;};

expr_or returns [Type return_type]: expr_and expr_or_tmp{$return_type = Tools.expr_or_typeCheck($expr_and.return_type , $expr_or_tmp.return_type);};

expr_or_tmp returns [Type return_type]: 'or' expr_and expr_or_tmp{$return_type = Tools.expr_or_tmp_typeCheck($expr_and.return_type , $expr_or_tmp.return_type);} |{$return_type = null;};

expr_and returns [Type return_type]: expr_eq expr_and_tmp{$return_type = Tools.expr_and_typeCheck($expr_eq.return_type , $expr_and_tmp.return_type);};

expr_and_tmp returns [Type return_type]: 'and' expr_eq expr_and_tmp{$return_type = Tools.expr_and_tmp_typeCheck($expr_eq.return_type , $expr_and_tmp.return_type);} |{$return_type = null;};

expr_eq returns [Type return_type]: expr_cmp expr_eq_tmp{$return_type = Tools.expr_eq_typeCheck($expr_cmp.return_type , $expr_eq_tmp.return_type);};

expr_eq_tmp returns [Type return_type]: ('==' | '<>') expr_cmp expr_eq_tmp{$return_type = Tools.expr_eq_tmp_typeCheck($expr_cmp.return_type , $expr_eq_tmp.return_type);} |{$return_type = null;};

expr_cmp returns [Type return_type]: expr_add expr_cmp_tmp{$return_type = Tools.expr_cmp_typeCheck($expr_add.return_type , $expr_cmp_tmp.return_type);};

expr_cmp_tmp returns [Type return_type]: ('<' | '>') expr_add expr_cmp_tmp{$return_type = Tools.expr_cmp_tmp_typeCheck($expr_add.return_type, $expr_cmp_tmp.return_type);} |{$return_type = null;};

expr_add returns [Type return_type]: expr_mult expr_add_tmp {$return_type = Tools.expr_add_typeCheck($expr_mult.return_type, $expr_add_tmp.return_type);};

expr_add_tmp returns [Type return_type]: ('+' | '-') expr_mult expr_add_tmp {$return_type = Tools.expr_add_tmp_typeCheck();} |{$return_type = null;};

expr_mult returns [Type return_type]: expr_un expr_mult_tmp {$return_type = Tools.expr_mult_typeCheck($expr_un.return_type, $expr_mult_tmp.return_type);};

expr_mult_tmp returns [Type return_type]: ('*' | '/') expr_un expr_mult_tmp{$return_type=Tools.expr_mult_tmp_typeCheck($expr_un.return_type,$expr_mult_tmp.return_type);} |{$return_type = null;};

expr_un returns [Type return_type]: ('not' | '-') expr_un{$return_type = Tools.expr_un_typeCheck($expr_un.return_type);} | expr_mem{$return_type = $expr_mem.return_type;};

expr_mem returns[Type return_type]: expr_other expr_mem_tmp{$return_type = Tools.expr_mem_typeCheck($expr_other.return_type,$expr_mem_tmp.count);};

expr_mem_tmp returns [int count]: '[' expr1=expr ']' expr2=expr_mem_tmp 
{$count = $expr2.count + 1;}
| {$count = 0;};

expr_other returns [Type return_type]:
	CONST_NUM {$return_type = IntType.getInstance();}
	| CONST_CHAR {$return_type = CharType.getInstance();}
	| str=CONST_STR	 {$return_type = new ArrayType(CharType.getInstance(),$str.text.length()-2 );}
	| id=ID
  { 
            SymbolTableItem item = SymbolTable.top.get($id.text);
            if(item == null) {
								$return_type = NoType.getInstance();
                print($id.line + ") Item " + $id.text + " doesn't exist.");
            }
            else {
                SymbolTableVariableItemBase var = (SymbolTableVariableItemBase) item;
                print($id.line + ") Variable " + $id.text + " used.\t\t" +   "Base Reg: " + var.getBaseRegister() + ", Offset: " + var.getOffset());
								$return_type = var.getVariable().getType();
						}
  } 
	| '{' expr (',' expr)* '}' 
	| 'read' '(' num=CONST_NUM ')' {$return_type = new ArrayType(CharType.getInstance(),Integer.parseInt($num.text));}
	| '(' expr ')';

CONST_NUM: [0-9]+;

CONST_CHAR: '\'' . '\'';

CONST_STR: '"' ~('\r' | '\n' | '"')* '"';

NL: '\r'? '\n' { setText("new_line"); };

ID: [a-zA-Z_][a-zA-Z0-9_]*;

COMMENT: '#' (~[\r\n])* -> skip;

WS: [ \t] -> skip;