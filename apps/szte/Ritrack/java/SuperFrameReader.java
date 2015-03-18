import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.LinkedList;
import java.util.TreeSet;


public class SuperFrameReader {
	
	LinkedList<String> filelist;
	Hashtable<Integer, HashSet<SlotListener>> listeners = new Hashtable<>(); //maps a number of SlotListeners to a slot id
	MoteSettings ms;
	private String directory;
	
	public void registerListener(SlotListener newListener, int slotNumber){
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
		}
	}

	public SuperFrameReader(String directory, MoteSettings ms) {
		this.ms = ms;
		File baseDir = new File(directory);
		String files[] = baseDir.list();
		Arrays.sort(files);
		this.directory = baseDir.getAbsolutePath() + File.separator;
		filelist = new LinkedList<>();
		for( String file:files){
			filelist.add(file);
		}
	}
	
	private class ReadClass extends Thread{
		
		private double speed;
		private int lastSlotId = -1;
		private int lastSuperFrameId = -1;
		private LinkedList<Slot> inSlot = new LinkedList<>();
		private long lastTimeStamp = -1;

		public ReadClass(double speed){
			this.speed = speed==0?0:1/speed;
		}
		
		public long getLastTimeStamp(LinkedList<Slot> list){
			long ret=-1;
			for(Slot s:list){
				for(SlotMeasurement sm:s.measurements){
					if( sm.timestamp > ret)
						ret = sm.timestamp;
				}
			}
			return ret;
		}
		
		private void notifyListeners(LinkedList<Slot> slots) {
			for(Slot slot:slots){
				for(int slotid:new TreeSet<>(listeners.keySet())){
					if( slotid == slot.slotId ){
						for(SlotListener listener:listeners.get(slotid)){
							listener.slotReceived(slot, lastSuperFrameId);
						}
					}
				}
			}

		}
		
		@Override
	    public void run()
	    {
			while( !filelist.isEmpty() ){
				String fileName = filelist.pop();
				String[] ids = fileName.substring(0, fileName.lastIndexOf('.')).split("_");
				int superFrameId = Integer.parseInt(ids[0]);
				int slotId = Integer.parseInt(ids[1]);
				if( lastSuperFrameId != superFrameId ){
					if( lastTimeStamp == -1 ){
						notifyListeners(inSlot);
						if( speed > 0 ){
							lastTimeStamp = getLastTimeStamp(inSlot);
						}
					} else {
						long timestamp = getLastTimeStamp(inSlot);
						long wait = (long) (speed*(timestamp - lastTimeStamp));
						lastTimeStamp = timestamp;
						if( wait > 0){
							synchronized (this) {
								try {
									this.wait(wait);
								} catch (InterruptedException e) {
									// TODO Auto-generated catch block
									e.printStackTrace();
								}
							}
						}
						notifyListeners(inSlot);
					}
					inSlot = new LinkedList<>();
					lastSuperFrameId = superFrameId;
					lastSlotId = -1; //force slot change
				}
				if( lastSlotId != slotId ){
					inSlot.add(new Slot(slotId, ms.getNodeIds(slotId, MoteSettings.TX1).get(0), ms.getNodeIds(slotId, MoteSettings.TX2).get(0), ms.getNodeIds(slotId, MoteSettings.RX)));
					lastSlotId = slotId;
				}
				try {
					SlotMeasurement fromfile = SlotMeasurement.readSlotMeasurement(new File(directory + fileName), inSlot.getLast());
					inSlot.getLast().addMeasurement(fromfile);
				} catch (IOException e) {
					System.err.println("Unable to read file: "+directory+fileName+" skipping.");
				}
			}
	    }

	}
	
	public void read(double speed) {
		new ReadClass(speed).start();
	}
	
	//just for fast testing
	
	private static class Receiver implements SlotListener{

		@Override
		public void slotReceived(Slot receivedSlot, int sfcounter) {
			receivedSlot.print();			
		}
		
	}

	public static void main(String[] args) {
		if( args.length != 2 ){
			System.out.println("Usage: SuperFrameReader directory speed");
			System.exit(1);
		}
		MoteSettings moteSettings = null;
		
		try {
			moteSettings = new MoteSettings("settings.ini");
		} catch (Exception e) {
			System.err.println("Error: setting.ini is not readable");
			e.printStackTrace();
			System.exit(1);
		}
		
		SuperFrameReader reader = new SuperFrameReader(args[0], moteSettings);
		Receiver rec = new Receiver();
		
		for(int i=0; i<reader.ms.getNumberOfSlots();i++){
			if(reader.ms.hasMeasurements(i))
				reader.registerListener(rec,i);
		}

		reader.read(Double.parseDouble(args[1]));
	}

}
