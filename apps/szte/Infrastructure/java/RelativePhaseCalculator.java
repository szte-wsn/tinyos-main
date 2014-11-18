import java.lang.Math;
import java.util.ArrayList;

public class RelativePhaseCalculator implements SlotListener {
	
	public static final int STATUS_OK = 0;
	public static final int STATUS_PERIOD_DIFF_LARGE = 1;
	private static final float PERIOD_DIFF  = 0.1f;
	
	private ArrayList<Integer> registeredSlots;		
	private MoteSettings ms;
	private SuperFrameMerger sfm;	
	private ArrayList<RelativePhaseListener> listeners;
	private int rx1, rx2;
	private int tx1, tx2;
	

	public RelativePhaseCalculator(MoteSettings ms, SuperFrameMerger sfm, int rx1, int rx2, int tx1, int tx2) {
		this.ms = ms;
		this.sfm = sfm;
		this.rx1 = rx1;
		this.rx2 = rx2;
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
		ArrayList<Integer> rx1slots = ms.getSlotNumbers(rx1, MoteSettings.RX);
		ArrayList<Integer> rx2slots = ms.getSlotNumbers(rx2, MoteSettings.RX);
		for(int slot:tx1slots){
			if( tx2slots.contains(slot) && rx1slots.contains(slot) && rx2slots.contains(slot)){
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
		double relativePhase = 0.0;
		double avgPeriod = 0.0;
		int status = STATUS_OK;
		SlotMeasurement referenceNode = new SlotMeasurement(rx1, null);
		SlotMeasurement otherNode = new SlotMeasurement(rx2, null);

		ArrayList<SlotMeasurement> slotMeasures = receivedSlot.measurements;
		
		for(int i=0; i<slotMeasures.size(); i++){
			if(slotMeasures.get(i).nodeid == rx1)
				referenceNode = slotMeasures.get(i);
			if(slotMeasures.get(i).nodeid == rx2)
				otherNode = slotMeasures.get(i);
		}
		
		if( referenceNode.getErrorCode() != SlotMeasurement.NO_ERROR ){
			status = referenceNode.getErrorCode();
		} else if( otherNode.getErrorCode() != SlotMeasurement.NO_ERROR ){
			status = otherNode.getErrorCode();
		} else if(Math.abs(referenceNode.period - otherNode.period) > referenceNode.period*PERIOD_DIFF) {
			status = STATUS_PERIOD_DIFF_LARGE;
		} else {
			avgPeriod = (referenceNode.period + otherNode.period)/2;
			relativePhase = (referenceNode.phase - otherNode.phase);
			if(relativePhase < 0)
				relativePhase += avgPeriod;
			relativePhase = (2*Math.PI * relativePhase) / avgPeriod;
		}		
		for(RelativePhaseListener listener : listeners)
			listener.relativePhaseReceived(relativePhase, avgPeriod, status, receivedSlot.slotId, rx1, rx2);
	}
	
}