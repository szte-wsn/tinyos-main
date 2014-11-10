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
		
	static MoteIF moteInterface;
	SuperFrameMerger sfm;
	MoteSettings moteSettings;
	static PhoenixSource phoenix;
	DrawRelativePhase drp;
	RelativePhaseFileWriter rpfw;
	RelativePhaseMap rpm;

	public RelativePhaseTester(String settingsPath) {
		try {
			moteSettings=new MoteSettings(settingsPath);
		} catch (Exception e) {
			System.err.println("Error: setting.ini is not readable");
			e.printStackTrace();
			System.exit(1);
		}

		sfm = new SuperFrameMerger(moteInterface, moteSettings);
		for(int i=0; i<moteSettings.getNumberOfSlots();i++){
			if(moteSettings.hasMeasurements(i))
				sfm.registerListener(this,i);
		}    	
		
		drp = new DrawRelativePhase("Draw RelativePhase", "Relative Phase");
		
		if(saveToFile) {
			rpfw = new RelativePhaseFileWriter(RELATIVEPHASEPATH);
			rpm = new RelativePhaseMap(IMAGEPATH);
		}

    	for(int node:others){
    		RelativePhaseCalculator rpc = new RelativePhaseCalculator(moteSettings, sfm, reference, node, tx1, tx2);
    		rpc.registerListener(drp);
    		if(saveToFile) {
	    		rpc.registerListener(rpfw);
	    		rpc.registerListener(rpm);
    		}
		}
	}

	@Override
	public void slotReceived(Slot receivedSlot) {
		receivedSlot.print();
	}

	public static void usage() {
		System.err.println("Usage: RelativePhaseTester [-comm <source>] saveToFile(true or false) tx1 tx2 referenceNode rx1,rx2,rx3,...");
		System.exit(1);
	}
	
	private static void initalize(String[] args) {
		saveToFile = (args[2].equals("true"));
		tx1 = Integer.parseInt(args[3]);
		tx2 = Integer.parseInt(args[4]);
		reference = Integer.parseInt(args[5]);
		StringTokenizer st = new StringTokenizer(args[6],",");
		others = new int[st.countTokens()];
		for(int i=0; st.hasMoreElements(); i++) 
			others[i] = (Integer.parseInt((String) st.nextElement()));
	}

	public static void main(String[] args) {
		String source = null;
		if (args.length == 7) {
			if (!args[0].equals("-comm")) {
				usage();
			}
			source = args[1];
		} else if (args.length != 0) {
			usage();
		}

		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}
		initalize(args);
		moteInterface = new MoteIF(phoenix);
		new RelativePhaseTester("settings.ini");
	}
}