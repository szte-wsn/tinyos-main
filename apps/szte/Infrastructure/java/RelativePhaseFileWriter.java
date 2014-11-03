import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Date;



class FileRecord{
	
	private String path;
	
	public FileRecord(String path) {
		this.path = path;
	}
	
	public void writeToFile(double relativePhase, double avgPeriod, int status, String fileName) {
		try {
			BufferedWriter out = new BufferedWriter(new FileWriter(path + fileName + ".txt", true));	
			out.write(String.format("Relative phase: %10.7f Avarage period: %10.5f Status: %2d Time: %5tc\n", relativePhase, avgPeriod, status, new Date()));
			out.close();
		} catch(IOException e) {
			e.printStackTrace();
		}
	}
}

public class RelativePhaseFileWriter implements RelativePhaseListener{
	
	private FileRecord fr;
	
	public RelativePhaseFileWriter(String path) {
		File dir = new File(path);
		dir.mkdirs();
		fr = new FileRecord(path);
	}

	public void relativePhaseReceived(final double relativePhase, final double avgPeriod, final int status, int slotId, int rx1, int rx2) {
		final String str = slotId + ":" + rx1 + "," + rx2;
		new Thread() {
			public void run() {
				fr.writeToFile(relativePhase, avgPeriod, status, str);
			}
		}.start();	
	}
	
}
