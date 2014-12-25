import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;


public class PhaseDistributionMeasureTester {

	static PhoenixSource phoenix;
	static MoteIF moteInterface;
	MoteSettings moteSettings;
	SuperFrameMerger sfm;

	public PhaseDistributionMeasureTester(String settings, int reference, int measured){
		try {
			moteSettings = new MoteSettings(settings);
		} catch (Exception e) {
			System.err.println("Error: setting.ini is not readable");
			e.printStackTrace();
			System.exit(1);
		}
		
		sfm = new SuperFrameMerger(moteInterface, moteSettings);
		PhaseDistributionMeasure pdm = new PhaseDistributionMeasure();
    	RelativePhaseCalculator rpc = new RelativePhaseCalculator(moteSettings, sfm, reference, measured, 1, 2);
    	rpc.registerListener(pdm);

	}

	public static void main(String[] args) {
		String source = null;
		source = args[1];

		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}
		moteInterface = new MoteIF(phoenix);
		new PhaseDistributionMeasureTester("settings.ini", 3, 4);
	}
}
