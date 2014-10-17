import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;


public class MoteSettings {
	public static final String TX1="TX1";
	public static final String TX2="TX2";
	public static final String RX="RX";
	private static final int NODEIDSHIFT=1;
	
	private ArrayList<String[]> settings = new ArrayList<String[]>();
	private int slotNumber;
	
	public void readSettings(Path settingsPath) throws Exception{
		List<String> temp = Files.readAllLines(settingsPath);
		for(String line:temp){
			line = line.replaceAll("\\s",""); //remove whitespaces
			line = line.replace("{",""); //and unnecesseary chars
			line = line.replace("}","");
			line = line.replace(";","");
			line = line.toUpperCase();
			if( line.lastIndexOf("//") >= 0){ //comments
				line = line.substring(0, line.lastIndexOf("//")); 
			}
			if( line.endsWith(",")) //trailing ","
				line = line.substring(0, line.length()-1);
			String[] settingsline = line.split(",");
			if( !line.isEmpty() )
				settings.add(settingsline);
		}
		slotNumber = settings.get(0).length;
		for(String[] settingsline:settings){
			if( settingsline.length != slotNumber )
				throw new Exception("Slotnumbers doesn't match");
		}
	}
	
	public int getNodeNumber(){
		return settings.size();
	}
	
	public int getSlotNumber(){
		return slotNumber;
	}
	
	public MoteSettings(String pathstring) throws Exception {
		readSettings(Paths.get(pathstring));
	}
	
	public boolean hasMeasurements(int slotnumber){
		for(int i=0;i<settings.size();i++){
			if( settings.get(i)[slotnumber].equals(RX) )
				return true;
		}
		return false;
	}
	
	public ArrayList<Integer> getNodeIds(int slotnumber, String type){
		ArrayList<Integer> ret = new ArrayList<Integer>();
		for(int i=0;i<settings.size();i++){
			if( settings.get(i)[slotnumber].equals(type) )
				ret.add(i+NODEIDSHIFT);
		}
		return ret;
	}
	
	public ArrayList<Integer> getSlotNumber(int nodeid, String type){
		ArrayList<Integer> ret = new ArrayList<Integer>();
		for(int i=0;i<slotNumber;i++){
			if( settings.get(nodeid-NODEIDSHIFT)[i].equals(type) )
				ret.add(i);
		}
		return ret;
	}


}
