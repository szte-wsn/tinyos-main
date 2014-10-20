import java.lang.Math;
import java.util.ArrayList;

public class RelativePhaseCalculator implements SlotListener {
	
	//private MultiHashMap<Integer, RelativePhaseSlotListener> listeners;
	private ArrayList<Integer> registeredSlots;		
	private MoteSettings ms;
	private SuperFrameMerger sfm;	
	private RelativePhaseListener rpsl;
	//private ArrayList<Integer> senders;
	//private ArrayList<Integer> receivers;
	private int rx1, rx2;
	private int tx1, tx2;
	private int avgPeriod;
	private boolean firstPeriod;
	

	public RelativePhaseCalculator(MoteSettings ms, SuperFrameMerger sfm, int rx1, int rx2, int tx1, int tx2, RelativePhaseListener rpsl) {
		this.ms = ms;
		this.sfm = sfm;
		this.rx1 = rx1;
		this.rx2 = rx2;
		this.tx1 = tx1;
		this.tx2 = tx2;
		this.rpsl = rpsl;
		//listeners = new MultiHashMap<Integer, RelativePhaseSlotListener>();
		//registeredSlots = new ArrayList<Integer>();
		firstPeriod = true;
		avgPeriod = 0;
		registerSlots();		
	}
	
	public void registerSlots() {
		for(int i=0; i<ms.getNumberOfSlots(); i++){
			ArrayList<Integer> nodes = ms.getNodeIds(i,MoteSettings.RX);
			int sender1 = ms.getNodeIds(i, MoteSettings.TX1).get(0);
			int sender2 =	ms.getNodeIds(i, MoteSettings.TX2).get(0);
			if((tx1 == sender1 && tx2 == sender2) || (tx1 == sender2 && tx2 == sender1)) {
				int number = 0;
				for(int n : nodes) {
					if(rx1 == n || rx2 == n)
						number++;
				}
				//Slot contains all receiver and tx
				if(number == 2) {
					registeredSlots.add(i);
					sfm.registerListener(this,i);
				}
			}
		}
	}
	
	//deregistered from all slots
	public void shutDown() {
		for(int i : registeredSlots)
			sfm.deregisterListener(this,i);
	}
	
	public void slotReceived(Slot receivedSlot) {
		calculateRelativePhases(receivedSlot);
	}

	public void calculateRelativePhases(Slot receivedSlot) {
		int relativePhase = 0;
		String status = "OK";
		//nem tudjuk, hogy a measurement, hogy tarolja az adatokat, hanyadik nodehoz tartozik pl az elso meres?
		ArrayList<SlotMeasurement> slotMeasures = receivedSlot.measurements;
		SlotMeasurement referenceNode = slotMeasures.get(0);
		SlotMeasurement otherNode = slotMeasures.get(1);
		if(referenceNode.period == 0) {
			status = "PERIOD ZERO ";
		} else {
			relativePhase = (otherNode.phase - referenceNode.phase) % referenceNode.period;
			if(relativePhase < 0)
				relativePhase += referenceNode.period;
			relativePhase = (int) ((2*Math.PI * relativePhase) / referenceNode.period);
			if(firstPeriod) {
				avgPeriod = referenceNode.period;
				firstPeriod = false;
			} else
				avgPeriod = (avgPeriod + referenceNode.period) / 2;
		}
		if(referenceNode.phase == 0 || otherNode.phase == 0)
			status += "PHASE ZERO ";
		if(Math.abs(referenceNode.period - avgPeriod) > 3)
			status += "PERIOD DIFFERENCE LARGE";
		rpsl.relativePhaseReceived(relativePhase, avgPeriod, status);
		/*Iterator it = listeners.iterator(receivedSlot.slotId);
		while(it.hasNext());
			it.next().relativePhaseReceived(relativePhase, avgPeriod, status);*/
	}
	
	/*
	public void registerListener(RelativePhaseSlotListener newListener, int slotNumber){
		listeners.put(slotNumber, newListener);
	}
	
	public void deregisterListener(RelativePhaseSlotListener oldListener, int slotNumber){
		listeners.remove(slotNumber, oldListener);		
	}*/
}
