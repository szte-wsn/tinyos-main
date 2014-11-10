import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Date;

class SlotMeasurement {
	public static final int CALCULATION_ERROR = 1;
	public static final int FILEVERSION = 1;
	public int nodeid, phaseRef, minimum, maximum, period, phase;
	public boolean hasMeasurement, hasWaveForm, hasLocalMeasurement;
	
	private ArrayList<Short> waveForm = new ArrayList<Short>();
	private Slot inSlot;
	private long timestamp = 0;
	
	
	public SlotMeasurement(int nodeid, Slot inSlot){
		hasMeasurement = false;
		hasWaveForm = false;
		hasLocalMeasurement = false;
		this.nodeid = nodeid;
		this.inSlot = inSlot;
	}
	
	public void setMeasurement(int phaseRef, int minimum, int maximum, int period, int phase){
		hasMeasurement = true;
		this.phaseRef = phaseRef;
		this.minimum = minimum;
		this.maximum = maximum;
		this.period = period;
		this.phase = phase;
		if( timestamp == 0 )
			timestamp = new Date().getTime();
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
		if( timestamp == 0 )
			timestamp = new Date().getTime();
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
	
	public void saveToFile(String filename, String directory, boolean addNodeId, boolean addSlotId) throws IOException{
		File dir = new File(directory);
		if ( !dir.exists() ){
			dir.mkdirs();
		}
		String stringpath=directory+"/"+filename;
		if(addSlotId)
			stringpath+="_"+String.format("%02d",inSlot.slotId);
		if(addNodeId)
			stringpath+="_"+String.format("%04d",nodeid);
		stringpath+=".raw";
		Path path = Paths.get(stringpath);
		
		ByteArrayOutputStream bos = new ByteArrayOutputStream(); 
		DataOutputStream dos = new DataOutputStream(bos);
		if( isWaveFormComplete() ){
			dos.writeInt(waveForm.size());
			for(short meas:waveForm){
				dos.writeByte((byte)meas);
			}
		} else {
			dos.writeInt((byte)0);
		}
		dos.writeShort(SlotMeasurement.FILEVERSION);
		dos.writeInt(nodeid);
		if( inSlot != null ){
			dos.writeInt(inSlot.tx1);
			dos.writeInt(inSlot.tx2);
			dos.writeShort(inSlot.slotId);
		} else {
			dos.writeInt(-1);
			dos.writeInt(-1);
			dos.writeShort(-1);
		}
		dos.writeLong(timestamp);
		if(hasMeasurement){
			dos.writeShort(period);
			dos.writeShort(phase);
		} else {
			dos.writeShort(-1);
			dos.writeShort(-1);
		}
		dos.close();
		Files.write(path, bos.toByteArray()); //creates, overwrites
	}
}