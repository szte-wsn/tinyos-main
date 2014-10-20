import java.util.ArrayList;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.LinkedList;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;


public class SuperFrameMerger implements MessageListener{
	
	Hashtable<Integer, HashSet<SlotListener>> listeners; //maps a number of SlotListeners to a slot id
	MoteSettings ms;
	LinkedList<ArrayList<Slot>> superFrames = new LinkedList<ArrayList<Slot>>();
	int lastSlot;
	private MoteIF moteInterface;
	
	public ArrayList<Slot> replaceSuperFrame(boolean init){
		ArrayList<Slot> superFrameSkeleton = new ArrayList<Slot>();
		for(int i=0;i<ms.getSlotNumber();i++){
			if(ms.hasMeasurements(i)){
				superFrameSkeleton.add(new Slot(
						i,
						ms.getNodeIds(i, MoteSettings.TX1).get(0),
						ms.getNodeIds(i, MoteSettings.TX2).get(0),
						ms.getNodeIds(i, MoteSettings.RX)
						));
			} else {
				superFrameSkeleton.add(null);
			}
		}
		superFrames.addLast(superFrameSkeleton);
		if(!init)
			return superFrames.removeFirst();
		else
			return superFrames.getFirst();
	}
	
	public SuperFrameMerger(MoteIF moteInterface, String motesettingsPath) throws Exception{
		this.moteInterface = moteInterface;
		ms = new MoteSettings(motesettingsPath);
		listeners = new Hashtable<>();
		
		replaceSuperFrame(true);
		replaceSuperFrame(true);
		lastSlot = -1;
	}
	
	public void registerListener(SlotListener newListener, int slotNumber){
		if(listeners.isEmpty())
			moteInterface.registerListener(new SyncMsg(), this);
		HashSet<SlotListener> listenerset = listeners.get(slotNumber);
		if( listenerset == null )
			listenerset = new HashSet<>();
		listenerset.add(newListener);
		listeners.put(slotNumber, listenerset);
	}
	
	public void deregisterListener(SlotListener oldListener, int slotNumber){
		HashSet<SlotListener> listenerset = listeners.get(slotNumber);
		if( listenerset == null || !listenerset.contains(oldListener) ){
			throw new IllegalArgumentException("Listener wasn't registered for this slot "+ slotNumber);
		}
		listenerset.remove(oldListener);
		if( listenerset.isEmpty() ){
			listeners.remove(slotNumber);
			if(listeners.isEmpty())
				moteInterface.deregisterListener(new SyncMsg(), this);
		}
	}
	

	@Override
	public void messageReceived(int to, Message m) {
		SyncMsg msg = (SyncMsg)m;
		int currentSlot = msg.get_frame()-1;
		int dataSource = msg.getSerialPacket().get_header_src();
		if( currentSlot <= lastSlot ){
			ArrayList<Slot> signalData = replaceSuperFrame(false);
			for(int slotid:listeners.keySet()){
				for(SlotListener listener:listeners.get(slotid)){
					listener.slotReceived(signalData.get(slotid));
				}
			}
		} 
		ArrayList<Integer> activeSlots = ms.getSlotNumber(dataSource, MoteSettings.RX);
		for(int i=0;i<msg.getSettingsNum();i++){
			int receivedslot = activeSlots.get(i);
			SlotMeasurement meas = new SlotMeasurement(dataSource,
					msg.getElement_phaseRef(i),
					msg.getElement_min(i),
					msg.getElement_max(i),
					msg.getElement_freq(i),
					msg.getElement_phase(i));
			if( receivedslot < currentSlot ){
				superFrames.getLast().get(receivedslot).addMeasurement(meas);
			} else {
				superFrames.getFirst().get(receivedslot).addMeasurement(meas);
			}
		}
		lastSlot = currentSlot;
	}

}
