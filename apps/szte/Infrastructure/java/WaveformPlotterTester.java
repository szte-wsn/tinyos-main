import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;


public class WaveformPlotterTester implements SlotListener {

	char mode;
	short slotOrMoteNumber;

	WaveformPlotter wfprs;

	static MoteIF moteInterface;
	SuperFrameMerger sfm;
	MoteSettings moteSettings;
	static PhoenixSource phoenix;

	public WaveformPlotterTester(String settingsPath, char mode , short slotOrMoteNumber) {
		try {
			moteSettings=new MoteSettings(settingsPath);
		} catch (Exception e) {
			System.err.println("Error: setting.ini is not readable");
			e.printStackTrace();
			System.exit(1);
		}
		this.mode = mode;
		this.slotOrMoteNumber = slotOrMoteNumber;
		sfm = new SuperFrameMerger(moteInterface, moteSettings);
		if(mode == 'S'){
			wfprs = new WaveformPlotter(slotOrMoteNumber+". slot");
			sfm.registerListener(this,slotOrMoteNumber);
			for( int nodeid: moteSettings.getNodeIds(slotOrMoteNumber, MoteSettings.RX))
				wfprs.addWaveform( (short) nodeid);
		}
		if(mode == 'M'){
			wfprs = new WaveformPlotter(slotOrMoteNumber+". mote");
			for( int slot :moteSettings.getSlotNumbers(slotOrMoteNumber, MoteSettings.RX)){
				sfm.registerListener(this,slot);
				wfprs.addWaveform( (short) slot);
			}
		}
	}

	@Override
	public void slotReceived(Slot receivedSlot) {
		if(mode == 'S'){
			for(SlotMeasurement meas:receivedSlot.measurements){
				if( meas.hasWaveForm )
					wfprs.plot(meas.getWaveForm(), (short) meas.nodeid );
			}
		}
		if(mode == 'M'){
			for(SlotMeasurement meas:receivedSlot.measurements){
				if( meas.hasWaveForm )
					wfprs.plot(meas.getWaveForm(), (short) receivedSlot.slotId );
			}
		}
		
	}

	public static void usage() {
		System.err.println("Usage: WaveformPlotterTester [-comm <source>]  [-Mx / -Rx |  x mote / slot number] ");
		System.exit(1);
	}



	public static void main(String[] args) {
		String source = null;
		char localMode = 'S';
		short localslotOrMoteNumber = 0;
		if ( args.length == 1 ){
			localMode = args[0].charAt(1);  //-Sx or -Mx -> S or M
			localslotOrMoteNumber = Short.parseShort(args[0].substring(2)); // x from -Sx or -Mx
		} else if (args.length == 3) {
			if (args[0].equals("-comm")) {
				source = args[1];
				localMode = args[2].charAt(1);  //-Sx or -Mx -> S or M
				localslotOrMoteNumber = Short.parseShort(args[2].substring(2)); // x from -Sx or -Mx
			} else if (args[1].equals("-comm")) {
				source = args[2];
				localMode = args[0].charAt(1);  //-Sx or -Mx -> S or M
				localslotOrMoteNumber = Short.parseShort(args[0].substring(2)); // x from -Sx or -Mx
			} else
				usage();
		} else {
			usage();
		}

		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}


		moteInterface = new MoteIF(phoenix);
		new WaveformPlotterTester("settings.ini",localMode, localslotOrMoteNumber);

	}



}
