import java.util.StringTokenizer;

import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

public class RelativePhaseTester implements SlotListener {
	
	public static final String RELATIVEPHASEPATH = "relativePhases/";
	public static final String IMAGEPATH = "images/";
	
	static int reference;
	static int[] others;
	static int tx1;
	static int tx2;
	static boolean saveToFile;
	static boolean summarizeData;
		
	static MoteIF moteInterface;
	SuperFrameMerger sfm;
	MoteSettings moteSettings;
	static PhoenixSource phoenix;
	DrawRelativePhase drp;
	RelativePhaseFileWriter rpfw;
	RelativePhaseMap rpm;
	ErrorsWriteToConsole ewtc;

	public RelativePhaseTester(String settingsPath, int refNode, int[] otherNode) {
		try {
			moteSettings = new MoteSettings(settingsPath);
		} catch (Exception e) {
			System.err.println("Error: setting.ini is not readable");
			e.printStackTrace();
			System.exit(1);
		}

		sfm = new SuperFrameMerger(moteInterface, moteSettings);
		ewtc = new ErrorsWriteToConsole();
		for(int i=0; i<moteSettings.getNumberOfSlots();i++){
			if(moteSettings.hasMeasurements(i)){
				sfm.registerListener(this, i);
				sfm.registerListener(ewtc, i);
			}
		}   
		
		drp = new DrawRelativePhase("Draw RelativePhase", "Relative Phase");
		rpm = new RelativePhaseMap(IMAGEPATH, refNode, otherNode, saveToFile, summarizeData);

		if(saveToFile) {
			rpfw = new RelativePhaseFileWriter(RELATIVEPHASEPATH);
		}
		
    	for(int node:others){
    		RelativePhaseCalculator rpc = new RelativePhaseCalculator(moteSettings, sfm, reference, node, tx1, tx2);
    		rpc.registerListener(drp);
    		rpc.registerListener(rpm);
    		if(saveToFile) {
	    		rpc.registerListener(rpfw);
    		}
		}; 
    	

	}

	@Override
	public void slotReceived(Slot receivedSlot) {
		//receivedSlot.print();
	}

	public static void usage() {
		System.err.println("Usage: RelativePhaseTester saveToFile(true or false) summarizeData(true or false) tx1 tx2 referenceNode rx1,rx2,rx3,...,rxN [-comm <source>]");
		System.exit(1);
	}
	
	private static int[] initalize(String[] args) {
		saveToFile = (args[0].equals("true"));
		summarizeData = (args[1].equals("true"));
		tx1 = Integer.parseInt(args[2]);
		tx2 = Integer.parseInt(args[3]);
		reference = Integer.parseInt(args[4]);
		StringTokenizer st = new StringTokenizer(args[5],",");
		others = new int[st.countTokens()];
		for(int i=0; st.hasMoreElements(); i++) 
			others[i] = (Integer.parseInt((String) st.nextElement()));
		return others;
	}

	public static void main(String[] args) {
		String source = null;
		int[] otherNodes;
		if (args.length == 8) {
			if (!args[6].equals("-comm")) {
				usage();
			}
			source = args[7];
		} else if (args.length == 6) {
			source = "sf@localhost:9002";
		} else {
			usage();
		}

		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}
		otherNodes = initalize(args);
		moteInterface = new MoteIF(phoenix);
		new RelativePhaseTester("settings.ini", Integer.parseInt(args[4]), otherNodes);
	}
}
