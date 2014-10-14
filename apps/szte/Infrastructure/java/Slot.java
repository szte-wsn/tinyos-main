import java.util.ArrayList;

class Slot{
  public int tx1, tx2;
  public ArrayList<SlotMeasurement> receivers;
  
  
  public Slot(int tx1, int tx2, ArrayList<SlotMeasurement> receivers){
    this.tx1=tx1;
    this.tx2=tx2;
    this.receivers=receivers;
  }
}