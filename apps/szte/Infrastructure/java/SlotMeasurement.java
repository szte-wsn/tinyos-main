import java.util.ArrayList;

class SlotMeasurement {
	public static final int CALCULATION_ERROR = 1;
	public int nodeid, phaseRef, minimum, maximum, period, phase;
	public boolean hasMeasurement, hasWaveForm, hasLocalMeasurement;
	
	private ArrayList<Short> waveForm = new ArrayList<Short>();
	
	
	public SlotMeasurement(int nodeid){
		hasMeasurement = false;
		hasWaveForm = false;
		hasLocalMeasurement = false;
		this.nodeid = nodeid;
	}
	
	public void setMeasurement(int phaseRef, int minimum, int maximum, int period, int phase){
		hasMeasurement = true;
		this.phaseRef = phaseRef;
		this.minimum = minimum;
		this.maximum = maximum;
		this.period = period;
		this.phase = phase;
	}
	
	public void setLocalMeasurement(int phaseRef, int minimum, int maximum,	int period, int phase){
		//TODO
	}

	public void addToWaveForm(int offset, short[] data) {
		hasWaveForm = true;
		while(waveForm.size() < offset+data.length )
			waveForm.add((short) -1);
		for(int i=0;i<data.length;i++)
			waveForm.set(offset+i, data[i]);
	}

	public Short[] getWaveForm() {
		Short[] ret = new Short[waveForm.size()];
		for(int i=0;i<waveForm.size();i++){
			ret[i] = waveForm.get(i);
		}
		return ret;
	}
	
	public boolean isWaveFormComplete() {
		if( waveForm.size() != Consts.BUFFER_LEN_MIG )
			return false;
		for(short element:waveForm){
			if(element < 0)
				return false;
		}
		return true;
	}

	public void print() {
		String line = String.format("RX: %5d dataStart: %3d min: %3d max: %3d period: %5d phase: %3d", nodeid, phaseRef, minimum, maximum, period, phase);
		System.out.print(line);
		if( isWaveFormComplete() )
			System.out.println(" WF saved");
		else
			System.out.println("");
	}
}