import java.util.ArrayList;

class Slot {
	public int tx1, tx2, slotId;
	public ArrayList<Integer> receivers;
	public ArrayList<SlotMeasurement> measurements;

	public Slot(int slotId, int tx1, int tx2, ArrayList<Integer> receivers) {
		this.slotId = slotId;
		this.tx1 = tx1;
		this.tx2 = tx2;
		this.receivers = receivers;
		this.measurements = new ArrayList<SlotMeasurement>();
	}

	public void print() {
		String line = String.format("Slot: %2d TX: %5d/%5d RX: ", slotId, tx1, tx2);
		for(Integer rx:receivers){
			line+=String.format("%5d/",rx);
		}
		line = line.substring(0,line.length()-1);
		line+=String.format(" Received measurements: %2d",measurements.size());
		System.out.println(line);
		for(SlotMeasurement m:measurements){
			m.print();
		}
	}
	
	public int printtoFile(int superframeNumber) {
		String line = String.format("%6d %5d %5d ", superframeNumber, tx1, tx2);
		for(Integer rx:receivers){
			line+=String.format("%5d ",rx);
			for(SlotMeasurement m:measurements){
				if(m.nodeid == rx){
					if(m.getErrorCode() != SlotMeasurement.NO_ERROR){
						return superframeNumber;
					}
					line+=String.format("%5d  ",m.period);
					line+=String.format("%5d  ",m.phase);
				}
			}
		}
		System.out.println(line);
		return superframeNumber+1;
	}
	

	public boolean addMeasurement(int dataSource, int period, short phase) {
		
		for(int i=0;i<measurements.size();i++){
			if( measurements.get(i).nodeid == dataSource ){
				measurements.get(i).setMeasurement(period, phase);
				return true;
			}
		}
		SlotMeasurement meas = new SlotMeasurement(dataSource, this);
		meas.setMeasurement(period, phase);
		measurements.add(meas);
		return false;
	}
	
	public boolean addtoWaveform(int dataSource, int offset, short[] data) {
		
		for(int i=0;i<measurements.size();i++){
			if( measurements.get(i).nodeid == dataSource ){
				measurements.get(i).addToWaveForm(offset, data);
				return true;
			}
		}
		SlotMeasurement meas = new SlotMeasurement(dataSource, this);
		meas.addToWaveForm(offset, data);
		measurements.add(meas);
		return false;
	}
}