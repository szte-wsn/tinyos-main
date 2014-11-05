import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

public class RelativePhaseTester implements SlotListener {
	
	public static final boolean SAVE_TO_FILE = true;
	public static final String RELATIVEPHASEPATH = "relativePhases/";
	public static final String IMAGEPATH = "images/";

	int reference = 4;
	int[] others = {3,5,6};
	int tx1 = 1;
	int tx2 = 2;
		
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
		
		if(SAVE_TO_FILE) {
			rpfw = new RelativePhaseFileWriter(RELATIVEPHASEPATH);
			rpm = new RelativePhaseMap(IMAGEPATH);
		}

    	for(int node:others){
    		RelativePhaseCalculator rpc = new RelativePhaseCalculator(moteSettings, sfm, reference, node, tx1, tx2);
    		rpc.registerListener(drp);
    		if(SAVE_TO_FILE) {
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
		System.err.println("Usage: Tester [-comm <source>]");
		System.exit(1);
	}

	public static void main(String[] args) {
		String source = null;
		if (args.length == 2) {
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
		
		moteInterface = new MoteIF(phoenix);
		new RelativePhaseTester("settings.ini");
	}
}
