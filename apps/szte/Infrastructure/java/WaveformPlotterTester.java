import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;

import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;


public class WaveformPlotterTester implements SlotListener {

	private WaveformPlotter wfpr;
	char mode;
	short slotOrMoteNumber;

	WaveformPlotter wfprs;
	ArrayList<Integer> displayedMotesOrSlots = new ArrayList<Integer>();

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
		}
		if(mode == 'M'){
			wfprs = new WaveformPlotter(slotOrMoteNumber+". mote");
			int numOfMotes = moteSettings.getNumberOfMotes();
			for(int i=0;i<numOfMotes;i++){
				if( i+1 == slotOrMoteNumber){
					ArrayList<Integer> receiverSlots = moteSettings.getSlotNumbers(slotOrMoteNumber, "RX");
					for( int slot : receiverSlots ){
						sfm.registerListener(this,slot);
					}
				}
			}
		}
	}

	@Override
	public void slotReceived(Slot receivedSlot) {
		if(mode == 'S'){
			if(receivedSlot.slotId== slotOrMoteNumber){
				ArrayList<Integer> receivers = receivedSlot.receivers;
				for(int i:receivers){
					if(!displayedMotesOrSlots.contains(i)){
						displayedMotesOrSlots.add(i);
						wfprs.addWaveform( (short) i);
					}else{
						for(SlotMeasurement meas:receivedSlot.measurements){
							if(meas.nodeid == i && meas.hasWaveForm){
								try{
									wfprs.plot(meas.getWaveForm(), (short) i );
								}catch(Exception e){
									System.out.println("Error during drawing the waveform.\n");
								}
							}
						}
					}
				}
			}
		}
		if(mode == 'M'){
			ArrayList<Integer> receivers = receivedSlot.receivers;
			for(int i:receivers){
				if( i == slotOrMoteNumber){
					if(!displayedMotesOrSlots.contains(receivedSlot.slotId)){
						displayedMotesOrSlots.add(receivedSlot.slotId);
						wfprs.addWaveform( (short) receivedSlot.slotId);
					}else{
						for(SlotMeasurement meas:receivedSlot.measurements){
							if(meas.nodeid == slotOrMoteNumber && meas.hasWaveForm){
								try{
									wfprs.plot(meas.getWaveForm(), (short) receivedSlot.slotId );
								}catch(Exception e){
									System.out.println("Error during drawing the waveform.\n");
								}
							}
						}
					}
				}
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
		if (args.length == 3) {
			if (!args[0].equals("-comm")) {
				usage();
			}
			source = args[1];
			localMode = args[2].charAt(1);  //-Sx or -Mx -> S or M
			localslotOrMoteNumber = Short.parseShort(args[2].substring(2)); // x from -Sx or -Mx
		} else if (args.length != 0) {
			usage();
		}

		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}


		moteInterface = new MoteIF(phoenix);
		WaveformPlotterTester tester = new WaveformPlotterTester("settings.ini",localMode, localslotOrMoteNumber);

	}



}
