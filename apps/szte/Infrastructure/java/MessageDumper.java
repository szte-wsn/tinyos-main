import java.io.BufferedOutputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import net.tinyos.message.Message;
import net.tinyos.message.MessageListener;
import net.tinyos.message.MoteIF;
import net.tinyos.packet.BuildSource;
import net.tinyos.packet.PhoenixSource;
import net.tinyos.util.PrintStreamMessenger;


public class MessageDumper implements MessageListener {

	private MoteIF mif;
	private DataOutputStream out;

	public MessageDumper(MoteIF mif, String filename) {
		this.mif = mif;
	    this.mif.registerListener(new SyncMsg(), this);
	    this.mif.registerListener(new WaveForm(), this);
	    
	    
	    File file = new File(filename);
	    try {
			out = new DataOutputStream(new BufferedOutputStream(new FileOutputStream(file)));
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	@Override
	public void messageReceived(int to, Message m) {
		try {
			if( m instanceof SyncMsg ){
				out.writeByte(SyncMsg.AM_TYPE);
			} else if ( m instanceof WaveForm ){
				out.writeByte(WaveForm.AM_TYPE);
			}
			out.writeByte(m.dataLength());
			out.write(m.dataGet());
			out.flush();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public static void main(String[] args) throws Exception {
	    if (args.length != 1) {
	    	System.out.println("Usage MessageDumper outfile");
	    	System.exit(1);
	    }
	    
	    PhoenixSource phoenix;
	    phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);

	    MoteIF mif = new MoteIF(phoenix);
	    new MessageDumper(mif, args[0]);
	  }

}
