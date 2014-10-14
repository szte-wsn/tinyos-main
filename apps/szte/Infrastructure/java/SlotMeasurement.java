import java.util.ArrayList;

class SlotMeasurement{
  public static final int CALCULATION_ERROR=1;
  public int nodeid, phaseRef, minimum, maximum, period, phase;
  private ArrayList<Integer> waveForm = new ArrayList<Integer>();
  
  public SlotMeasurement(int nodeid, int phaseRef, int minimum, int maximum, int period, int phase){
    this.nodeid=nodeid;
    this.phaseRef=phaseRef;
    this.minimum=minimum;
    this.maximum=maximum;
    this.period=period;
    this.phase=phase;
  }
  
  public void addToWaveForm(int offset, ArrayList<Integer> newWaveForm){
    
  }
  
  public ArrayList<Integer> getWaveForm(){
    return waveForm;
  }
}