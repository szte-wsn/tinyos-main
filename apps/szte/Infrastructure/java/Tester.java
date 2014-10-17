import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;

public class Tester implements SlotListener {
	static MoteIF moteInterface;
	SuperFrameMerger sfm;

	public Tester(String settingsPath) {
		try {
			sfm = new SuperFrameMerger(moteInterface, settingsPath);
		} catch (Exception e) {
			System.err.println("Error: setting.ini is not readable");
			e.printStackTrace();
			System.exit(1);
		}
		sfm.registerListener(this);
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
		PhoenixSource phoenix;

		if (source == null) {
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		} else {
			phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
		}

		moteInterface = new MoteIF(phoenix);
		new Tester("settings.ini");

	}

}
