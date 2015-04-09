import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;


public class MoteSettings {
	public static final String TX1="TX1";
	public static final String TX2="TX2";
	public static final String RX="RX";
	public static final String SSYN="SSYN";
	private static final int NODEIDSHIFT=1;
	
	private ArrayList<String[]> settings = new ArrayList<String[]>();
	private int slotNumber;
	
	public void readSettings(Path settingsPath) throws Exception{
		List<String> temp = Files.readAllLines(settingsPath, StandardCharsets.UTF_8);
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
	
	public int getNumberOfMotes(){
		return settings.size();
	}
	
	public int getNumberOfSlots(){
		return slotNumber;
	}
	
	public boolean isDataSync(int slotnumber, int sender){
		try {
			if( settings.get(sender-NODEIDSHIFT)[slotnumber].equals(SSYN) )
				return true;
			else
				return false;
		} catch( ArrayIndexOutOfBoundsException e ){
			/* Ok, this is ugly: but this is a very common exception. Usually, the first few
			 * slots are active, then comes the debug slots. This is the only point where the
			 * debug slots matters, so we cheat a bit, and let the motesettings.ini to be the same 
			 */
			return false;
		}
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
	
	public ArrayList<Integer> getSlotNumbers(int nodeid, String type){
		ArrayList<Integer> ret = new ArrayList<Integer>();
		for(int i=0;i<slotNumber;i++){
			if( settings.get(nodeid-NODEIDSHIFT)[i].equals(type) )
				ret.add(i);
		}
		return ret;
	}
	
	public ArrayList<Integer> getSlotNumbersBetween(int nodeid, String type, int before, String betweenType){
		ArrayList<Integer> temp = new ArrayList<>();
		boolean getAll = false;
		if( before == -1 ){
			before = slotNumber - 1;
			getAll = true;
		}
		if( before >= slotNumber )
			before = slotNumber-1;
		
		boolean adding = false;
		boolean foundAll = false;
		int checked = 0;
		while( !foundAll ) {
			String currentType = settings.get(nodeid-NODEIDSHIFT)[before];
			if( !adding ){//searching for before
				if( currentType.equals(betweenType) ){
					adding = true;
					if( getAll )
						checked = 0;
				} 
			} else {
				if( currentType.equals(type) ){
					temp.add(before);
				} else if( currentType.equals(betweenType) ) {
					foundAll = true;
				}
			}
			if( ++checked == slotNumber )
				foundAll = true;
			if( --before < 0 )
				before = slotNumber-1;
		}
		//we found everything we can, but it's in reverse order
		ArrayList<Integer> ret = new ArrayList<>();
		for(int i=temp.size()-1; i>=0 ; i--)
			ret.add(temp.get(i));	
		return ret;
	}


}