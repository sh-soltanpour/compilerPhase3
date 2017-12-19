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
	{beginScope();} 'actor' ID '<' CONST_NUM '>' NL (
		state
		| receiver
		| NL
	)* 'end' {endScope();} (NL | EOF);

state: type ID (',' ID)* NL;

receiver:
	{beginScope();} 'receiver' recName=ID '(' (var1=type ID{SymbolTable.define();} (',' var2=type ID{SymbolTable.define();})*)? ')' NL statements 'end' NL 
	{	
		endScope();
	};

type
	returns[Type return_type]:
	'char' {$return_type = CharType.getInstance();} (
		'[' size = CONST_NUM {
			int size = Integer.parseInt($size.text);
			
			$return_type= new ArrayType($return_type,size);} ']'
	)*
	| 'int' {$return_type = IntType.getInstance();} (
		'[' size = CONST_NUM {
			int size = Integer.parseInt($size.text);
			
			$return_type= new ArrayType($return_type,size);} ']'
	)*;

block:
	{beginScope();} 'begin' NL statements 'end' NL {endScope();};

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
	type id1=ID { SymbolTable.define(); } ('=' var2=expr 
	{
		SymbolTableItem item = SymbolTable.top.get($id1.text);
		if(item instanceof SymbolTableVariableItemBase){
				SymbolTableVariableItemBase var = (SymbolTableVariableItemBase) item;
				Tools.expr_assign_typeCheck(var.getVariable().getType(), $var2.return_type);
		}		
	}
	)? (
	',' id2=ID { SymbolTable.define(); } ('=' var2=expr
		{
			SymbolTableItem item = SymbolTable.top.get($id2.text);
			if(item instanceof SymbolTableVariableItemBase){
				SymbolTableVariableItemBase var = (SymbolTableVariableItemBase) item;
				Tools.expr_assign_typeCheck(var.getVariable().getType(), $var2.return_type);
			}
		}
		)?
	)* NL;

stm_tell:{ArrayList<Type> types = new ArrayList<Type>();}
	(actorId = ID | 'sender' | actorId='self') '<<' recName=ID '(' (var1=expr{types.add($var1.return_type);} (',' var2=expr{types.add($var2.return_type);})*)? ')' NL
	{		
			if ($actorId.text.equals("self")){
				if(SymbolTable.top.hasReceiver($recName.text, types))
					print("rec found");
				else
					print("rec not found");
			}
			else{
				SymbolTableActorItem actorItem = SymbolTable.top.getActor($actorId.text);
				
				if (actorItem == null){
					Tools.pass2Error = true;
					print("actor not found");
				}
				else{
					if(actorItem.getSymbolTable().hasReceiver($recName.text, types))
						print("rec found");
					else
						print("rec not found");
				}
			}
	};

stm_write: 'write' '(' var1=expr ')' NL{Tools.checkWriteArgument($var1.return_type);};

stm_if_elseif_else:
	'if' var1=expr{Tools.checkConditionType($var1.return_type);} NL statements ('elseif' var2=expr {Tools.checkConditionType($var2.return_type);} NL statements)* (
		'else' NL statements
	)? 'end' NL;

stm_foreach: 'foreach' ID 'in' expr NL statements 'end' NL;

stm_quit: 'quit' NL;

stm_break: 'break' NL;

stm_assignment: expr NL;

expr
	returns[Type return_type]:
	expr_assign {$return_type = $expr_assign.return_type;
	if ($return_type != null)
		System.out.println("EXPR type: " + $return_type.toString());};

expr_assign
	returns[Type return_type]:
	var1=expr_or '=' var2=expr_assign {$return_type = Tools.expr_assign_typeCheck($var1.return_type, $var2.return_type);}
	| expr_or {$return_type = $expr_or.return_type;};

expr_or
	returns[Type return_type]: var1=expr_and var2=expr_or_tmp{$return_type = Tools.expr_mult_typeCheck($var1.return_type, $var2.return_type);};

expr_or_tmp
	returns[Type return_type]:
	'or' var1=expr_and var2=expr_or_tmp{$return_type = Tools.expr_mult_tmp_typeCheck($var1.return_type, $var2.return_type);}
	| {$return_type = null;};

expr_and
	returns[Type return_type]: var1=expr_eq var2=expr_and_tmp {$return_type = Tools.expr_mult_typeCheck($var1.return_type, $var2.return_type);};

expr_and_tmp
	returns[Type return_type]:
	'and' var1=expr_eq var2=expr_and_tmp {$return_type = Tools.expr_mult_tmp_typeCheck($var1.return_type, $var2.return_type);}
	| {$return_type = null;};

expr_eq
	returns[Type return_type]: var1=expr_cmp var2=expr_eq_tmp{$return_type = Tools.expr_eq_tmp_typeCheck($var1.return_type, $var2.return_type);
		
	};

expr_eq_tmp
	returns[Type return_type]: ('==' | '<>') var1=expr_cmp var2=expr_eq_tmp {$return_type = Tools.expr_eq_tmp_typeCheck($var1.return_type, $var2.return_type);}
	| {$return_type = null;};

expr_cmp
	returns[Type return_type]:
	var1 = expr_add var2 = expr_cmp_tmp {$return_type = Tools.expr_mult_typeCheck($var1.return_type, $var2.return_type);
	
		};

expr_cmp_tmp
	returns[Type return_type]: ('<' | '>') var1 = expr_add var2 = expr_cmp_tmp {$return_type = Tools.expr_mult_tmp_typeCheck($var1.return_type, $var2.return_type);}
	| {$return_type = null;};

expr_add
	returns[Type return_type]:
	var1 = expr_mult var2 = expr_add_tmp {$return_type = Tools.expr_mult_typeCheck($var1.return_type, $var2.return_type);
	
	};

expr_add_tmp
	returns[Type return_type]: ('+' | '-') var1 = expr_mult var2 = expr_add_tmp {$return_type = Tools.expr_mult_tmp_typeCheck($var1.return_type, $var2.return_type);
		}
	| {$return_type = null;};

expr_mult
	returns[Type return_type]:
	var1 = expr_un var2 = expr_mult_tmp {$return_type = Tools.expr_mult_typeCheck($var1.return_type, $var2.return_type);
		};

expr_mult_tmp
	returns[Type return_type]: ('*' | '/') var1 = expr_un var2 = expr_mult_tmp {$return_type = Tools.expr_mult_tmp_typeCheck($var1.return_type, $var2.return_type);
		}
	| {$return_type = null;};

expr_un
	returns[Type return_type]: ('not' | '-') expr_un_var = expr_un {$return_type = Tools.expr_un_typeCheck($expr_un_var.return_type);
		}
	| expr_mem {$return_type = $expr_mem.return_type;};

expr_mem
	returns[Type return_type]:
	expr_other expr_mem_tmp {$return_type = Tools.expr_mem_typeCheck($expr_other.return_type,$expr_mem_tmp.count);
		};

expr_mem_tmp
	returns[int count]:
	'[' expr1 = expr ']' expr2 = expr_mem_tmp {$count = $expr2.count + 1;}
	| {$count = 0;};

expr_other
	returns[Type return_type]:
	CONST_NUM {$return_type = IntType.getInstance();}
	| CONST_CHAR {$return_type = CharType.getInstance();}
	| str = CONST_STR {$return_type = new ArrayType(CharType.getInstance(),$str.text.length()-2 );}
	| id = ID { 
						
            SymbolTableItem item = SymbolTable.top.get($id.text);
	          if(!(item instanceof SymbolTableVariableItemBase)) {
								Tools.putLocalVar($id.text, NoType.getInstance());
								SymbolTable.define();
								$return_type = NoType.getInstance();
                print($id.line + ") Item " + $id.text + " doesn't exist.");
            }
            else {
							System.out.println("Now we are here");
                SymbolTableVariableItemBase var = (SymbolTableVariableItemBase) item;
                print($id.line + ") Variable " + $id.text + " used.\t\t" +   "Base Reg: " + var.getBaseRegister() + ", Offset: " + var.getOffset());
								$return_type = var.getVariable().getType();
						}
  }
	|{ArrayList <Type> types = new ArrayList<Type>();} '{' var1=expr{types.add($var1.return_type);}
	 (',' var2=expr{types.add($var2.return_type);})* '}' {$return_type = Tools.arrayInitTypeCheck(types);}
	| 'read' '(' num = CONST_NUM ')' {$return_type = new ArrayType(CharType.getInstance(),Integer.parseInt($num.text));
		}
	| '(' var1=expr ')' {$return_type = $var1.return_type;} ;

CONST_NUM: [0-9]+;

CONST_CHAR: '\'' . '\'';

CONST_STR: '"' ~('\r' | '\n' | '"')* '"';

NL: '\r'? '\n' { setText("new_line"); };

ID: [a-zA-Z_][a-zA-Z0-9_]*;

COMMENT: '#' (~[\r\n])* -> skip;

WS: [ \t] -> skip;