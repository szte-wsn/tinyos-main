import java.io.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import javax.swing.JFrame;
import javax.swing.JPanel;
import java.awt.*;


class PlotFunctionPanel extends JPanel{

	int width,heigth;
	public int[] data;
	static final int yScaleFactor = 20;
	static final int xScaleFactor = 3;
	static final int maxRssiValue = 30;
	static final int bufferLength = 500;
	static final int startTreshold = 5;
	
	public PlotFunctionPanel(int width,int heigth){
		this.width = width;
		this.heigth = heigth;
		data = new int[bufferLength];
		setPreferredSize(new Dimension(width, heigth+50));
	}
	
	public void paintComponent(Graphics g){
		int start=0;
		int end=bufferLength;
		int temp[] = new int[128];
		int tempcnt = 0;
		int absmin = 30;
		int absminind = 0;
		int absmax = 0;
		int absmaxind = 0;
		int mintresh = 0;
		int minstart[] = new int[50];
		int minstartind = 0;
		int minend[] = new int[50];
		int minendind = 0;
		int state = 0;
		Font font = new Font("font",5,50);
		super.paintComponent(g); 
        Graphics2D g2d = (Graphics2D) g.create();
		g2d.setFont(font);
		//draw horizontal lines
		for(int i=0;i<maxRssiValue*yScaleFactor;i+=yScaleFactor){
			g2d.drawLine(0,heigth-i,width,heigth-i);
		}
		//draw vertical lines
		for(int i=0;i<width;i+=xScaleFactor){
			g2d.drawLine(i,0,i,heigth);
		}
		g2d.setColor(Color.RED);
		g2d.setStroke(new BasicStroke(3, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
		
		for(int i=10; i<bufferLength-1; i++){
		  if(data[i]>startTreshold){
			  //System.out.println("New treshold: " + data[i]);
				start=i;
				break;
			}
		}
		for(int i=bufferLength-1; i>0; i--) {
		  if(data[i]>startTreshold){
				end=i;
				break;
			}
		}
		//System.out.println("Start point: " + start + " End point: " + end);
		//draw the waveform
		g2d.setColor(Color.BLUE);
		for(int i=0;i<bufferLength-1;i++){
			g2d.drawLine(i*xScaleFactor,heigth-data[i],(i+1)*xScaleFactor,heigth-data[i+1]);
		}
		
		//search for min and max values
		for(int i=start+2; i<end-2; i++){
			if(data[i]<absmin){
			  //System.out.println("min: " + data[i] + " " + absmin);
				absmin = data[i];
				absminind = i;
			}
			if(data[i]>absmax){
			  //System.out.println("max: " + data[i] + " " + absmax);
				absmax = data[i];
				absmaxind = i;
			}
		}
		//System.out.println("absmin: " + absmin + " absminind " + absminind + " absmax " + absmax + " absmaxind " + absmaxind);
		g2d.setColor(Color.BLACK);
		g2d.setColor(Color.RED);
		//draw an oval at the min and max points
		g2d.drawOval(absminind*xScaleFactor-2,heigth-absmin-2,4,4);
		g2d.drawOval(absmaxind*xScaleFactor-2,heigth-absmax-2,4,4);
		//calculate a threshold value
		mintresh=absmin+((absmax-absmin)>>1);
		//System.out.println("mintresh " + mintresh);
		//draw a line at the mintresh
		g2d.drawLine(0,heigth-mintresh,width,heigth-mintresh);
		//finds the minimum regions defined by: values that smaller than mintresh 
		//the minimum regions defined by two values: start and end of the region (minstart,minend)
		for(int i=start+2; i<end-2; i++){
			if(state == 0 && data[i]<=mintresh){
				state = 1;
				minstart[minstartind++] = i;
			}
			if(state == 1 && data[i]>=mintresh){
				state = 0;
				minend[minendind++] = i-1;
			}
		}
		//calculate period 
		int period = 0;
		int period_end = 0;
		if(minendind>=8)
		  period_end = 8;
		else if(minendind>=4)
		  period_end = 4;
		else if(minendind>=2)
		  period_end = 2;
		int firstPlace,secondPlace;
		for(int i=0; i<period_end; i++) {
      firstPlace = (minstart[i]+minend[i])>>1;
      secondPlace = (minstart[i+1]+minend[i+1])>>1;
      period += secondPlace - firstPlace;
      g2d.setColor(Color.GREEN);
      g2d.drawOval(firstPlace*xScaleFactor-2,heigth-data[firstPlace]-2,4,4);
      g2d.drawOval(secondPlace*xScaleFactor-2,heigth-data[secondPlace]-2,4,4);
      g2d.setColor(Color.BLACK);
		}
		//System.out.println("Period_end: " + period_end + "\n\n");
		period = period >> period_end;
		g2d.drawString("Period: " + period + "[sample]",10*xScaleFactor,heigth+20);
		//calculate phase
		int phase = 0;
		if(period != 0) 
		  phase = (minstart[0]+minend[0])>>1 % period;
		else
		  phase = phase = (minstart[0]+minend[0])>>1;
		g2d.drawString("Phase: " + phase + "[sample]",10*xScaleFactor,heigth+60);
		repaint();
	}
}


class ProcessWave{

  static int dataCounter = 0;
	static byte data[] = new byte[512];
	static int x[] = new int[512];
	static JFrame frame;
	static PlotFunctionPanel panel;
	static final int numberOfDataPerMessage = 60;
	static final int firstDataIndex = 8;
	static final int bufferLength = 500;
	static final int maxRssiValue = 30;
	static final int amRadioMsg = 7;
	static final int amIdIndex = 7;
	static final int yScaleFactor = 20;
	static final int xScaleFactor = 3;

	public static void printByte(PrintStream p, int b) {
    String bs = Integer.toHexString(b & 0xff).toUpperCase();
    if (b >=0 && b < 16)
      p.print("0");
    p.print(bs + " ");
  }


public static void printPacketTimeStamp(PrintStream p, byte[] packet){
		if(packet[amIdIndex] == amRadioMsg){
			for(int i=firstDataIndex;i<firstDataIndex+numberOfDataPerMessage;i++){
			  //System.out.println("packet["+dataCounter+"]: " + packet[i]);
				panel.data[dataCounter] = (int)(packet[i] & 0xFF);
				dataCounter++;
				if(dataCounter == bufferLength){
					dataCounter = 0;
					frame.getContentPane().add(panel);
					frame.pack();
					frame.setVisible(true);
					break;
				}
			}
		} else {
			dataCounter = 0;
		}
	}

    public static void main(String args[]) throws IOException {
      String source = null;
      PacketSource reader;
      if (args.length == 2 && args[0].equals("-comm")) {
        source = args[1];
      } else if (args.length > 0) {
      	System.err.println("usage: java DrawWaveform [-comm PACKETSOURCE]");
     		System.err.println("       (default packet source from MOTECOM environment variable)");
      	System.exit(2);
		  }
      if (source == null) {	
    		reader = BuildSource.makePacketSource();
      } else {
    		reader = BuildSource.makePacketSource(source);
      }
		  if (reader == null) {
      	System.err.println("Invalid packet source (check your MOTECOM environment variable)");
      	System.exit(2);
		  }

		  frame = new JFrame("Plot Function");
		  frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		  panel = new PlotFunctionPanel(bufferLength*xScaleFactor, maxRssiValue*yScaleFactor);

		  try {
		    reader.open(PrintStreamMessenger.err);
		    for (;;) {
      		byte[] packet = reader.readPacket();
      		printPacketTimeStamp(System.out, packet);
      		System.out.flush();
		    }
		  }
		  catch (IOException e) {
      	System.err.println("Error on " + reader.getName() + ": " + e);
		  }
    }
}

