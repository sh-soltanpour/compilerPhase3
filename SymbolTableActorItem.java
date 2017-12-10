public class SymbolTableActorItem extends SymbolTableItem {
  public SymbolTableActorItem(Actor actor, int offset) {
    this.actor = actor;
    this.offset = offset;
  }

  @Override
  public String getKey() {
    return actor.getName();
  }

  public int getOffset() {
    return offset;
  }

  Actor actor;
  int offset;
}