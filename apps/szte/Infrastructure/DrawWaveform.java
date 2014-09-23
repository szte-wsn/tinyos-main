// $Id: Listen.java,v 1.5 2010-06-29 22:07:41 scipio Exp $

/*									tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the University of California nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
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
		setPreferredSize(new Dimension(width, heigth));
	}
	
	public void paintComponent(Graphics g){
		int start=0;
		int temp[] = new int[128];
		int tempcnt = 0;
		int absmin = 500;
		int absminind = 0;
		int absmax = 0;
		int absmaxind = 0;
		int mintresh = 0;
		int minstart[] = new int[20];
		int minstartind = 0;
		int minend[] = new int[20];
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
		
		for(int i=10;i<bufferLength-1;i++){
			if(data[i]>startTreshold){
				start=i;
				break;
			}
		}
		
		//draw the original waveform (0->start point)
		/*g2d.setColor(Color.BLUE);
		for(int i=0;i<start-1;i++){
			g2d.drawLine(i*xScaleFactor,heigth-data[i],(i+1)*xScaleFactor,heigth-data[i+1]);
		}*/
		
		//filtering
		for(int i=start;i<bufferLength-4;i+=4){
			temp[tempcnt++] = (data[i]+data[i+1]+data[i+2]+data[i+3])>>2;
		}
		//search for min and max values
		for(int i=10;i<tempcnt>>1;i++){
			if(temp[i]<absmin){
				absmin = temp[i];
				absminind = i;
			}
			if(temp[i]>absmax){
				absmax = temp[i];
				absmaxind = i;
			}
		}
		//draw the original waveform (start point->end)
		/*g2d.setColor(Color.BLACK);
		for(int i=0;i<bufferLength-1;i++){
			g2d.drawLine(i*xScaleFactor,heigth-data[i],(i+1)*xScaleFactor,heigth-data[i+1]);
		}*/
		g2d.setColor(Color.BLACK);
		//draw the filtered waveform
		for(int i=0;i<tempcnt-2;i++){
			g2d.drawLine(i*xScaleFactor,heigth-temp[i],(i+1)*xScaleFactor,heigth-temp[i+1]);
		}
		g2d.setColor(Color.RED);
		//draw an oval at the min and max points
		g2d.drawOval(absminind*xScaleFactor-2,heigth-absmin-2,4,4);
		g2d.drawOval(absmaxind*xScaleFactor-2,heigth-absmax-2,4,4);
		//calculate a threshold value
		mintresh=absmin+((absmax-absmin)>>2);
		//draw a line at the mintresh
		g2d.drawLine(0,heigth-mintresh,width,heigth-mintresh);
		//finds the minimum regions defined by: values that smaller than mintresh 
		//the minimum regions defined by two values: start and end of the region (minstart,minend)
		for(int i=10;i<tempcnt-2;i++){
			if(state == 0 && temp[i]<=mintresh){
				state = 1;
				minstart[minstartind++] = i;
			}
			if(state == 1 && temp[i]>mintresh){
				state = 0;
				minend[minendind++] = i-1;
			}
		}
		int firstMin=0;
		if(minendind<3 && minendind>0){
			int firstindex = (minstart[0]+minend[0])>>1;
			int secondindex = (minstart[1]+minend[1])>>1;
			int period = secondindex-firstindex;
			//draw ovals at the minimum points
			g2d.setColor(Color.GREEN);
			g2d.drawOval(firstindex*xScaleFactor-2,heigth-temp[firstindex]-2,4,4);
			g2d.drawOval(secondindex*xScaleFactor-2,heigth-temp[secondindex]-2,4,4);
			g2d.setColor(Color.BLACK);
			//Period: period * 4, because of the filter
			g2d.drawString("Period: "+period*4+"[sample]",firstindex*xScaleFactor,heigth+20);
			firstMin = firstindex;
		}else if(minendind>=3){
			int firstindex = (minstart[0]+minend[0])>>1;
			int secondindex = (minstart[1]+minend[1])>>1;	
			int thirdindex = (minstart[2]+minend[2])>>1;
			int period1 = secondindex-firstindex;
			int period2 = thirdindex-secondindex;
			//draw ovals at the minimum points
			g2d.setColor(Color.GREEN);
			g2d.drawOval(firstindex*xScaleFactor-2,heigth-temp[firstindex]-2,4,4);
			g2d.drawOval(secondindex*xScaleFactor-2,heigth-temp[secondindex]-2,4,4);
			g2d.drawOval(thirdindex*xScaleFactor-2,heigth-temp[secondindex]-2,4,4);
			//the final period value is the avarage of the two periods
			int period = (period1+period2)>>1;
			g2d.setColor(Color.BLACK);
			//Period: period * 4, because of the filter
			g2d.drawString("Period: "+period*4+"[sample]",firstindex*xScaleFactor,heigth+20);
			firstMin = firstindex;
		}
		//Phase
		g2d.drawString("Phase: "+firstMin*4+"[sample]",firstMin*xScaleFactor,heigth+60);
		repaint();
	}
}


public class DrawWaveform {

	static int dataCounter = 0;
	static byte data[] = new byte[500];
	static int x[] = new int[500];
	static JFrame frame;
	static PlotFunctionPanel panel;
	static final int numberOfDataPerMessage = 60;
	static final int firstDataIndex = 8;
	static final int bufferLength = 500;
	static final int maxRssiValue = 30;
	static final int amRadioMsg = 7;
	static final int amIdIndex = 7;
	static final int yScaleFactor = 20;
	static final int XscaleFactor = 3;

	public static void printByte(PrintStream p, int b) {
	String bs = Integer.toHexString(b & 0xff).toUpperCase();
	if (b >=0 && b < 16)
	    p.print("0");
	p.print(bs + " ");
    }

	public static void printPacketTimeStamp(PrintStream p, byte[] packet){
		if(packet[amIdIndex] == amRadioMsg){
			for(int i=firstDataIndex;i<firstDataIndex+numberOfDataPerMessage;i++){
				panel.data[dataCounter] = yScaleFactor*(int)(packet[i] & 0xFF);
				dataCounter++;
				if(dataCounter == bufferLength){
					dataCounter = 0;
					frame.getContentPane().add(panel);
					frame.pack();
					frame.setVisible(true);
					break;
				}
			}
		}else{
			dataCounter = 0;
		}
	}

    public static void main(String args[]) throws IOException {
        String source = null;
        PacketSource reader;
        if (args.length == 2 && args[0].equals("-comm")) {
          source = args[1];
        }
		else if (args.length > 0) {
	    	System.err.println("usage: java DrawWaveform [-comm PACKETSOURCE]");
	   		System.err.println("       (default packet source from MOTECOM environment variable)");
	    	System.exit(2);
		}
        if (source == null) {	
  	  		reader = BuildSource.makePacketSource();
        }
        else {
  	  		reader = BuildSource.makePacketSource(source);
        }
		if (reader == null) {
	    	System.err.println("Invalid packet source (check your MOTECOM environment variable)");
	    	System.exit(2);
		}

		frame = new JFrame("Plot Function");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		panel = new PlotFunctionPanel(XscaleFactor*bufferLength, yScaleFactor*maxRssiValue);

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

