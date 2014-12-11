import java.lang.Math;
import java.util.ArrayList;

public class RelativePhaseCalculator implements SlotListener {
	
	public static final int STATUS_OK = 0;
	public static final int STATUS_PERIOD_DIFF_LARGE = 1;
	public static final int STATUS_NO_DATA = 2;
	public static final int STATUS_NO_REFERENCE = 3;
	private static final float PERIOD_DIFF  = 0.1f;
	
	private ArrayList<Integer> registeredSlots;		
	private MoteSettings ms;
	private SuperFrameMerger sfm;	
	private ArrayList<RelativePhaseListener> listeners;
	private int reference, other;
	private int tx1, tx2;
	

	public RelativePhaseCalculator(MoteSettings ms, SuperFrameMerger sfm, int reference, int other, int tx1, int tx2) {
		this.ms = ms;
		this.sfm = sfm;
		this.reference = reference;
		this.other = other;
		this.tx1 = tx1;
		this.tx2 = tx2;
		listeners = new ArrayList<RelativePhaseListener>();
		registeredSlots = new ArrayList<Integer>();
		registerSlots();		
	}
	
	private void registerSlots() {
//		System.out.println("In registerSlots");
		ArrayList<Integer> tx1slots = ms.getSlotNumbers(tx1, MoteSettings.TX1);
		ArrayList<Integer> tx2slots = ms.getSlotNumbers(tx2, MoteSettings.TX2);
		ArrayList<Integer> refslots = ms.getSlotNumbers(reference, MoteSettings.RX);
		ArrayList<Integer> otherslots = ms.getSlotNumbers(other, MoteSettings.RX);
		for(int slot:tx1slots){
			if( tx2slots.contains(slot) && refslots.contains(slot) && otherslots.contains(slot)){
//				System.out.println("registered");
				registeredSlots.add(slot);
				sfm.registerListener(this,slot);
			}
		}
	}
	
	public void registerListener(RelativePhaseListener newListener){
		listeners.add(newListener);
	}
	
	public void deregisterListener(RelativePhaseListener oldListener){
		listeners.remove(oldListener);
	}
	
	//deregistered from all slots
	public void shutDown() {
		for(int i : registeredSlots)
			sfm.deregisterListener(this,i);
	}
	
	public void slotReceived(Slot receivedSlot) {
		calculateRelativePhases(receivedSlot);
	}

	private void calculateRelativePhases(Slot receivedSlot) {
		SlotMeasurement referenceNode = null;
		SlotMeasurement otherNode = null;

		ArrayList<SlotMeasurement> slotMeasures = receivedSlot.measurements;
		
		for(int i=0; i<slotMeasures.size(); i++){
			if(slotMeasures.get(i).nodeid == reference)
				referenceNode = slotMeasures.get(i);
			if(slotMeasures.get(i).nodeid == other)
				otherNode = slotMeasures.get(i);
		}
		if( otherNode == null ){
			for(RelativePhaseListener listener : listeners)
				listener.relativePhaseReceived(0, 0, STATUS_NO_DATA, receivedSlot.slotId, reference, other);
		} else if( referenceNode == null ){
			for(RelativePhaseListener listener : listeners)
				listener.relativePhaseReceived(0, 0, STATUS_NO_REFERENCE, receivedSlot.slotId, reference, other);
		} else {
			double relativePhase = 0.0;
			double avgPeriod = 0.0;
			int status = STATUS_OK;
			if( referenceNode.getErrorCode() != SlotMeasurement.NO_ERROR ){
				status = referenceNode.getErrorCode();
			} else if( otherNode.getErrorCode() != SlotMeasurement.NO_ERROR ){
				status = otherNode.getErrorCode();
			} else if(Math.abs(referenceNode.period - otherNode.period) > referenceNode.period*PERIOD_DIFF) {
				status = STATUS_PERIOD_DIFF_LARGE;
			} else {
				double referencePhase = 2*Math.PI * referenceNode.phase / referenceNode.period;
				double otherPhase = 2*Math.PI * otherNode.phase / otherNode.period;
				avgPeriod = (referenceNode.period + otherNode.period)/2;
				relativePhase = referencePhase - otherPhase;
				if(relativePhase < 0)
					relativePhase += 2*Math.PI;
				if( relativePhase > 2*Math.PI || relativePhase<0 ){
					System.out.println("R: "+referencePhase + " " + referenceNode.phase);
					System.out.println("O: "+otherPhase + " " + otherNode.phase);
					System.out.println("r: "+relativePhase);
				}
			}		
			for(RelativePhaseListener listener : listeners)
				listener.relativePhaseReceived(relativePhase, avgPeriod, status, receivedSlot.slotId, reference, other);
		}
	}
	
}