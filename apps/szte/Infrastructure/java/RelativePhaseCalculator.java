import java.lang.Math;
import java.util.ArrayList;

public class RelativePhaseCalculator implements SlotListener {
	
	/**
	 * ilyen nincs a JDKban, ha külső osztályt akarsz használni előbb kérdezz
	 */
	//private MultiHashMap<Integer, RelativePhaseSlotListener> listeners;
	private ArrayList<Integer> registeredSlots;		
	private MoteSettings ms;
	private SuperFrameMerger sfm;	
	private RelativePhaseListener rpsl;
	//private ArrayList<Integer> senders;
	//private ArrayList<Integer> receivers;
	private int rx1, rx2;
	private int tx1, tx2;
	/**
	 * Ezzel az avgPeriod-dal mi a szándékod? Nem vagyok benne biztos, hogy értem, de ha értem, akkor nem túl jó az implementáció
	 */
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
		/**
		 * TX1/TX2 nem véletlen van külön kezelve
		 * Ez kicsivel rövidebb
		 * miért public?
		 */
		ArrayList<Integer> tx1slots = ms.getSlotNumbers(tx1, MoteSettings.TX1);
		ArrayList<Integer> tx2slots = ms.getSlotNumbers(tx2, MoteSettings.TX2);
		ArrayList<Integer> rx1slots = ms.getSlotNumbers(rx1, MoteSettings.RX);
		ArrayList<Integer> rx2slots = ms.getSlotNumbers(rx2, MoteSettings.RX);
		for(int slot:tx1slots){
			if( tx2slots.contains(slot) && rx1slots.contains(slot) && rx2slots.contains(slot)){
				registeredSlots.add(slot);
				sfm.registerListener(this,slot);
			}
		}
//		
//		for(int i=0; i<ms.getNumberOfSlots(); i++){
//			ArrayList<Integer> nodes = ms.getNodeIds(i,MoteSettings.RX);
//			int sender1 = ms.getNodeIds(i, MoteSettings.TX1).get(0);
//			int sender2 =	ms.getNodeIds(i, MoteSettings.TX2).get(0);
//			if((tx1 == sender1 && tx2 == sender2) || (tx1 == sender2 && tx2 == sender1)) {
//				int number = 0;
//				for(int n : nodes) {
//					if(rx1 == n || rx2 == n)
//						number++;
//				}
//				//Slot contains all receiver and tx
//				if(number == 2) {
//					registeredSlots.add(i);
//					sfm.registerListener(this,i);
//				}
//			}
//		}
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
		/**
		 * miért public?
		 */
		int relativePhase = 0;
		/**
		 * A status inkább int legyen, ami public static final int értékeket vehet fel - most nagyon bogarászni kell, hogy mit vehet fel
		 */
		String status = "OK";
		//nem tudjuk, hogy a measurement, hogy tarolja az adatokat, hanyadik nodehoz tartozik pl az elso meres?
		/**
		 * de el van hozzá tárolva a nodeid, az alapján meg lehetne keresni
		 */
		ArrayList<SlotMeasurement> slotMeasures = receivedSlot.measurements;
		SlotMeasurement referenceNode = slotMeasures.get(0);
		SlotMeasurement otherNode = slotMeasures.get(1);
		if(referenceNode.period == 0) {
			/**
			 * és ha a másikon 0 a periódus?
			 */
			status = "PERIOD ZERO ";
		} else {
			/**
			 * Két periódusod van, azok átlagával kellene itt végig számolni
			 */
			relativePhase = (otherNode.phase - referenceNode.phase) % referenceNode.period;
			if(relativePhase < 0)
				relativePhase += referenceNode.period;
			/**
			 * gondolj már bele mi a radián. Ennek a kimenete 0..6.28 között van, ebből int-ként ló*** se látszik
			 */
			relativePhase = (int) ((2*Math.PI * relativePhase) / referenceNode.period);
			if(firstPeriod) {
				avgPeriod = referenceNode.period;
				firstPeriod = false;
			} else
				avgPeriod = (avgPeriod + referenceNode.period) / 2;
		}
		/**
		 * csomó számítást meg lehetne úszni, ha ezt a kettőt korábban ellenőriznéd
		 */
		if(referenceNode.phase == 0 || otherNode.phase == 0)
			status += "PHASE ZERO ";
		/**
		 * Ne használj magic konstansokat. Az  a 3 tipikusan olyan konstans, amit az ember finomhangolásnál állítgat. Erre van a public static final
		 */
		if(Math.abs(referenceNode.period - avgPeriod) > 3)
			status += "PERIOD DIFFERENCE LARGE";
		rpsl.relativePhaseReceived(relativePhase, avgPeriod, status);
		/*Iterator it = listeners.iterator(receivedSlot.slotId);
		while(it.hasNext());
			it.next().relativePhaseReceived(relativePhase, avgPeriod, status);*/
	}
	
	/**
	 * Ha valami már nem kell, töröld. Ok, tudom, itt most én kavartam a specifikációkkal, de a DataCollector is tele van kikommenttelt kóddal,
	 * ez elég átláthatatlanná teszi
	 */
	
	/*
	public void registerListener(RelativePhaseSlotListener newListener, int slotNumber){
		listeners.put(slotNumber, newListener);
	}
	
	public void deregisterListener(RelativePhaseSlotListener oldListener, int slotNumber){
		listeners.remove(slotNumber, oldListener);		
	}*/
}
