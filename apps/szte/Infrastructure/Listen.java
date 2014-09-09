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
	static final int yScaleFactor = 6;
	static final int xScaleFactor = 2;
	static final int maxRssiValue = 30;
	static final int bufferLength = 512;
	
	public PlotFunctionPanel(int width,int heigth){
		this.width = width;
		this.heigth = heigth;
		data = new int[bufferLength];
		setPreferredSize(new Dimension(width, heigth));
	}
	
	public void paintComponent(Graphics g){
		super.paintComponent(g); 
        Graphics2D g2d = (Graphics2D) g.create();
		for(int i=0;i<maxRssiValue*yScaleFactor;i+=yScaleFactor){
			g2d.drawLine(0,heigth-i,width,heigth-i);
		}
		for(int i=0;i<width;i+=xScaleFactor){
			g2d.drawLine(i,0,i,heigth);
		}
		g2d.setColor(Color.RED);
		g2d.setStroke(new BasicStroke(3, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
		for(int i=0;i<bufferLength-1;i++){
			g2d.drawLine(i*xScaleFactor,heigth-data[i],(i+1)*xScaleFactor,heigth-data[i+1]);
		}
		repaint();
	}
}


public class Listen {

	static int dataCounter = 0;
	static byte data[] = new byte[512];
	static int x[] = new int[512];
	static JFrame frame;
	static PlotFunctionPanel panel;
	static final int numberOfDataPerMessage = 60;
	static final int firstDataIndex = 8;
	static final int bufferLength = 512;
	static final int maxRssiValue = 30;
	static final int amRadioMsg = 7;
	static final int amIdIndex = 7;
	static final int yScaleFactor = 6;
	static final int XscaleFactor = 2;

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
	    	System.err.println("usage: java net.tinyos.tools.Listen [-comm PACKETSOURCE]");
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

