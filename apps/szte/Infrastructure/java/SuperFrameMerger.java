import java.util.ArrayList;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.LinkedList;
import java.util.TreeSet;

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
		for(int i=0;i<ms.getNumberOfSlots();i++){
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
	
	public SuperFrameMerger(MoteIF moteInterface, MoteSettings moteSettings){
		this.moteInterface = moteInterface;
		ms = moteSettings;
		listeners = new Hashtable<>();
		
		replaceSuperFrame(true);
		replaceSuperFrame(true);
		lastSlot = -1;
	}
	
	public void registerListener(SlotListener newListener, int slotNumber){
		if(listeners.isEmpty()){
			moteInterface.registerListener(new SyncMsg(), this);
			moteInterface.registerListener(new WaveForm(), this);
		}
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
			if(listeners.isEmpty()){
				moteInterface.deregisterListener(new SyncMsg(), this);
				moteInterface.deregisterListener(new WaveForm(), this);
			}
		}
	}
	

	@Override
	public void messageReceived(int to, Message m) {
		Integer dataSource = m.getSerialPacket().get_header_src();
		if( m instanceof SyncMsg ){
			SyncMsg msg = (SyncMsg)m;
			int currentSlot = msg.get_frame()-1;
			if(currentSlot < 0)
				currentSlot = ms.getNumberOfSlots()-1;
			if( ms.isDataSync(currentSlot, dataSource)){
				if( currentSlot <= lastSlot ){
					ArrayList<Slot> signalData = replaceSuperFrame(false);
					for(int slotid:new TreeSet<>(listeners.keySet())){
						for(SlotListener listener:listeners.get(slotid)){
							listener.slotReceived(signalData.get(slotid));
						}
					}
				} 
				ArrayList<Integer> activeSlots = ms.getSlotNumbers(dataSource, MoteSettings.RX);
				for(int i=0;i<msg.getSettingsNum();i++){
					int receivedslot = activeSlots.get(i);
					if( receivedslot < currentSlot ){
						superFrames.getLast().get(receivedslot).addMeasurement(
								dataSource,
								msg.getElement_freq(i),
								msg.getElement_phase(i)
								);
					} else {
						superFrames.getFirst().get(receivedslot).addMeasurement(
								dataSource,
								msg.getElement_freq(i),
								msg.getElement_phase(i)
								);
					}
				}
				lastSlot = currentSlot;
			}
		} else if( m instanceof WaveForm ){
			WaveForm msg = (WaveForm)m;
			ArrayList<Integer> rxSlots = ms.getSlotNumbers(dataSource, MoteSettings.RX);
			if( rxSlots.size() > msg.get_whichWaveform() ){
				int receivedslot = rxSlots.get(msg.get_whichWaveform());//which slot
				superFrames.getLast().get(receivedslot).addtoWaveform(dataSource, 
						msg.get_whichPartOfTheWaveform()*WaveForm.numElements_data(), //offset
						msg.get_data());
			}
		}
	}

}
