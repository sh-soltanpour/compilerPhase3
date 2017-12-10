import java.util.ArrayList;

public class Tools {
  static ArrayList<String> messages = new ArrayList<String> ();
  static boolean codeIsValid = true;
  static boolean oneActorDefined = false;
  static public void printMessages(){
		for(int i = 0 ; i < messages.size() ; i++){
			System.out.println(messages.get(i));
		}
	}
  static public boolean putActor(String name, int mailboxSize )  {
    boolean error = false;
    try {
      SymbolTable.top.put(new SymbolTableActorItem(new Actor(name, mailboxSize), SymbolTable.top.getOffset(Register.GP)));
    } catch (ItemAlreadyExistsException e) {
      error = true;
      Tools.putActor(name+"_temp_", mailboxSize);
    }
    return error;
  }
  
  static public boolean putReceiver(String name, ArrayList <Type> arguments)  {
    boolean error = false;
    try {
      SymbolTable.top.put(new SymbolTableReceiverItem(new Receiver(name, arguments), SymbolTable.top.getOffset(Register.SP)));    } 
      catch (ItemAlreadyExistsException e) {
      error = true;
      Tools.putReceiver(name+"_temp_", arguments);
    }
    return error;
  }
 static public boolean putLocalVar(String name, Type type){
    boolean error = false;
    try{
      SymbolTable.top.put(
              new SymbolTableLocalVariableItem(
                  new Variable(name, type),
                  SymbolTable.top.getOffset(Register.SP)
              )
          );
    }
    catch (ItemAlreadyExistsException e) {
      error = true;
      Tools.putLocalVar(name+"_temp_", type);
    }
    return error;
  }
  static public boolean putGlobalVar(String name, Type type){
    boolean error = false;
    try{
      SymbolTable.top.put(
        new SymbolTableGlobalVariableItem(
            new Variable(name, type),
            SymbolTable.top.getOffset(Register.GP)
        )
      );
  }  
   catch (ItemAlreadyExistsException e) {
      error = true;
      Tools.putGlobalVar(name+"_temp_", type);
    }
    return error;
  }
}