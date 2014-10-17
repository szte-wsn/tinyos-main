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

	public void addMeasurement(SlotMeasurement meas) {
		measurements.add(meas);
	}

	public void print() {
		String line = String.format("Slot: %2d TX: %5d/%5d RX: ", slotId, tx1, tx2);
		for(Integer rx:receivers){
			line+=String.format("%5d/",rx);
		}
		line = line.substring(0,line.length()-1);
		line+=String.format(" %5d",measurements.size());
		System.out.println(line);
		for(SlotMeasurement m:measurements){
			m.print();
		}
	}
}