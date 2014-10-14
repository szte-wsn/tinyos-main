import java.util.ArrayList;

class SuperFrame{
  private ArrayList<Slot> slots = new ArrayList<Slot>();
  
  public void addFrame(int slotnumber, Slot receivers){
    slots.ensureCapacity(slotnumber);
    slots.set(slotnumber, receivers);
  }
  
  public Slot getSlot(int slotnumber){
    return slots.get(slotnumber);
  }
  
  public ArrayList<Integer> getSlotsWhereNode(int nodeid, boolean receiver){
    ArrayList<Integer> ret=new ArrayList<Integer>();
    for(int i=0;i<(slots.size());i++){
      if( receiver ){
        for(SlotMeasurement rx:slots.get(i).receivers){
          if(rx.nodeid == nodeid){
            ret.add(i);
            break;
          }
        }
      } else {
        if( slots.get(i).tx1 == nodeid || slots.get(i).tx2 == nodeid ){
          ret.add(i);
        }
      }
    }
    return ret;
  }
}