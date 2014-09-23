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
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.KeyStroke;
import javax.swing.SwingUtilities;
import javax.swing.AbstractAction;  

class PlotFunctionPanel extends JPanel{

	int width,heigth;
	public int[][][] data;
	public int[][] motes;
	public int[][] slots;
	public int whichMote;
	public int whichPair;
	public boolean pairs;
	static final int yScaleFactor = 10;
	static final int xScaleFactor = 2;
	static final int maxRssiValue = 25;
	static final int bufferLength = 500;
	static final int startTreshold = 5;
	static final int numberOfInfrastMotes = 4;
	static final int numberOfRx = 6;
	static final int numberOfReceiverInSlot = 2;
	static final int numberOfSlots = 12;
	
	public PlotFunctionPanel(int width,int heigth){
		this.width = width;
		this.heigth = heigth;
		data = new int[numberOfInfrastMotes][numberOfRx][bufferLength];
		motes = new int[numberOfSlots][2];
		slots = new int[numberOfSlots][2];
		if(numberOfInfrastMotes == 4){
			motes[0]=new int[] {2,4};
			motes[1]=new int[] {2,3};
			motes[2]=new int[] {1,2};
			motes[3]=new int[] {2,3};
			motes[4]=new int[] {3,4};
			motes[5]=new int[] {1,3};
			motes[6]=new int[] {3,4};
			motes[7]=new int[] {2,4};
			motes[8]=new int[] {1,4};
			motes[9]=new int[] {1,4};
			motes[10]=new int[] {1,3};
			motes[11]=new int[] {1,2};
			slots[0]=new int[] {0,0};
			slots[1]=new int[] {1,0};
			slots[2]=new int[] {0,2};
			slots[3]=new int[] {3,1};
			slots[4]=new int[] {2,1};
			slots[5]=new int[] {1,3};
			slots[6]=new int[] {4,2};
			slots[7]=new int[] {4,3};
			slots[8]=new int[] {2,4};
			slots[9]=new int[] {3,5};
			slots[10]=new int[] {4,5};
			slots[11]=new int[] {5,5};
		}
		whichMote = 0;
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
		int minstart[] = new int[50];
		int minstartind = 0;
		int minend[] = new int[50];
		int minendind = 0;
		int state = 0;
		Font font = new Font("font",3,20);
		super.paintComponent(g); 
        Graphics2D g2d = (Graphics2D) g.create();
		g2d.setFont(font);
		int waveCnt=0;
		if(!pairs){
			for(waveCnt=0;waveCnt<numberOfRx;waveCnt++){
				int startY = (waveCnt%4)*maxRssiValue*yScaleFactor;
				int startX = (waveCnt/4)*bufferLength*xScaleFactor+((waveCnt/4)*20/*to separate waveforms*/);
				g2d.setColor(Color.BLACK);
				g2d.setStroke(new BasicStroke(1, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
				//draw rectangle to separate waveforms
				g2d.drawRect(startX,startY,bufferLength*xScaleFactor,maxRssiValue*yScaleFactor);
				//draw horizontal lines
	/*			for(int i=startY;i<startY+maxRssiValue*yScaleFactor;i+=yScaleFactor){
					g2d.drawLine(startX,i,startX+bufferLength*xScaleFactor,i);
				}*/
				//draw vertical lines
				/*for(int i=startX;i<startX+bufferLength*xScaleFactor;i+=xScaleFactor){
					g2d.drawLine(i,startY,i,startY+maxRssiValue*yScaleFactor);
				}*/
				g2d.setColor(Color.RED);
				g2d.setStroke(new BasicStroke(3, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
				for(int i=10;i<bufferLength-1;i++){
					if(data[whichMote][waveCnt][i]>startTreshold){
						start=i;
						break;
					}
				}
				//filtering
				for(int i=start;i<bufferLength-4;i+=4){
					temp[tempcnt++] = (data[whichMote][waveCnt][i]+data[whichMote][waveCnt][i+1]+data[whichMote][waveCnt][i+2]+data[whichMote][waveCnt][i+3])>>2;
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
				g2d.setColor(Color.BLACK);
				//draw the filtered waveform
				for(int i=0;i<tempcnt-2;i++){
					g2d.drawLine(startX+i*xScaleFactor,startY+maxRssiValue*yScaleFactor-temp[i],startX+(i+1)*xScaleFactor,startY+maxRssiValue*yScaleFactor-temp[i+1]);
				}		
				g2d.setColor(Color.RED);
				//draw an oval at the min and max points
				g2d.drawOval(startX+absminind*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-absmin-2,4,4);
				g2d.drawOval(startX+absmaxind*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-absmax-2,4,4);
				//calculate a threshold value
				mintresh=absmin+((absmax-absmin)>>2);
				//draw a line at the mintresh	
				g2d.setStroke(new BasicStroke(1, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
				g2d.drawLine(startX,startY+maxRssiValue*yScaleFactor-mintresh,startX+bufferLength*xScaleFactor,startY+maxRssiValue*yScaleFactor-mintresh);
				g2d.setStroke(new BasicStroke(3, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
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
				int period=0;
				if(minendind<3 && minendind>0){
					int firstindex = (minstart[0]+minend[0])>>1;
					int secondindex = (minstart[1]+minend[1])>>1;
					period = secondindex-firstindex;
					//draw ovals at the minimum points
					g2d.setColor(Color.GREEN);
					g2d.drawOval(startX+firstindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[firstindex]-2,4,4);
					g2d.drawOval(startX+secondindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[secondindex]-2,4,4);
					g2d.setColor(Color.BLACK);
					//Period: period * 4, because of the filter
					g2d.drawString("Period: "+period*4+"[sample]",startX+20,startY+20);
					firstMin = firstindex*4;
				}else if(minendind>=3){
					int firstindex = (minstart[0]+minend[0])>>1;
					int secondindex = (minstart[1]+minend[1])>>1;	
					int thirdindex = (minstart[2]+minend[2])>>1;
					int period1 = secondindex-firstindex;
					int period2 = thirdindex-secondindex;
					//draw ovals at the minimum points
					g2d.setColor(Color.GREEN);
					g2d.drawOval(startX+firstindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[firstindex]-2,4,4);
					g2d.drawOval(startX+secondindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[secondindex]-2,4,4);
					g2d.drawOval(startX+thirdindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[secondindex]-2,4,4);
					//the final period value is the avarage of the two periods
					period = (period1+period2)>>1;
					g2d.setColor(Color.BLACK);
					//Period: period * 4, because of the filter
					g2d.drawString("Period: "+period*4+"[sample]",startX+20,startY+20);
					firstMin = firstindex*4;
				}
				period = period*4;
				while(firstMin>period){
					firstMin-=period;
				}
				//Phase
				g2d.drawString("Phase: "+firstMin+"[sample]",startX+20,startY+40);

				tempcnt = 0;
				absmax = 0;
				absmaxind = 0;
				absmin = 300;
				absminind = 0;
				minstartind = 0;
				minendind = 0;
			}
		}else{
			g2d.drawString("Slot: "+whichPair,20,20);
			g2d.drawString("Motes: "+motes[whichPair][0]+" , "+motes[whichPair][1],20,40);		
			g2d.drawString("BufferCounters: "+slots[whichPair][0]+" , "+slots[whichPair][1],20,60);
			for(waveCnt=0;waveCnt<numberOfReceiverInSlot;waveCnt++){
				int startY = 100+(waveCnt%4)*maxRssiValue*yScaleFactor;
				int startX = 100+(waveCnt/4)*bufferLength*xScaleFactor+((waveCnt/4)*100/*to separate waveforms*/);
				g2d.setColor(Color.BLACK);
				g2d.setStroke(new BasicStroke(3, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
				for(int i=10;i<bufferLength-1;i++){
					if(data[motes[whichPair][waveCnt]-1][slots[whichPair][waveCnt]][i]>startTreshold){
						start=i;
						break;
					}
				}
				//filtering
				for(int i=start;i<bufferLength-4;i+=4){
					temp[tempcnt++] = (data[motes[whichPair][waveCnt]-1][slots[whichPair][waveCnt]][i]+data[motes[whichPair][waveCnt]-1][slots[whichPair][waveCnt]][i+1]+data[motes[whichPair][waveCnt]-1][slots[whichPair][waveCnt]][i+2]+data[motes[whichPair][waveCnt]-1][slots[whichPair][waveCnt]][i+3])>>2;
				}
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
				g2d.setColor(Color.BLACK);
				//draw the filtered waveform
				for(int i=0;i<tempcnt-2;i++){
					g2d.drawLine(startX+i*xScaleFactor,startY+maxRssiValue*yScaleFactor-temp[i],startX+(i+1)*xScaleFactor,startY+maxRssiValue*yScaleFactor-temp[i+1]);
				}		
				g2d.setColor(Color.RED);
				//draw an oval at the min and max points
				g2d.drawOval(startX+absminind*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-absmin-2,4,4);
				g2d.drawOval(startX+absmaxind*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-absmax-2,4,4);
				//calculate a threshold value
				mintresh=absmin+((absmax-absmin)>>2);
				//draw a line at the mintresh
				g2d.drawLine(startX,startY+maxRssiValue*yScaleFactor-mintresh,startX+bufferLength*xScaleFactor,startY+maxRssiValue*yScaleFactor-mintresh);
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
				int period=0;
				if(minendind<3 && minendind>0){
					int firstindex = (minstart[0]+minend[0])>>1;
					int secondindex = (minstart[1]+minend[1])>>1;
					period = secondindex-firstindex;
					//draw ovals at the minimum points
					g2d.setColor(Color.GREEN);
					g2d.drawOval(startX+firstindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[firstindex]-2,4,4);
					g2d.drawOval(startX+secondindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[secondindex]-2,4,4);
					g2d.setColor(Color.BLACK);
					//Period: period * 4, because of the filter
					g2d.drawString("Period: "+period*4+"[sample]",startX+20,startY+20);
					firstMin = firstindex*4;
				}else if(minendind>=3){
					int firstindex = (minstart[0]+minend[0])>>1;
					int secondindex = (minstart[1]+minend[1])>>1;	
					int thirdindex = (minstart[2]+minend[2])>>1;
					int period1 = secondindex-firstindex;
					int period2 = thirdindex-secondindex;
					//draw ovals at the minimum points
					g2d.setColor(Color.GREEN);
					g2d.drawOval(startX+firstindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[firstindex]-2,4,4);
					g2d.drawOval(startX+secondindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[secondindex]-2,4,4);
					g2d.drawOval(startX+thirdindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[secondindex]-2,4,4);
					//the final period value is the avarage of the two periods
					period = (period1+period2)>>1;
					g2d.setColor(Color.BLACK);
					//Period: period * 4, because of the filter
					g2d.drawString("Period: "+period*4+"[sample]",startX+20,startY+20);
					firstMin = firstindex*4;
				}
				period = period*4;
				while(firstMin>period && firstMin<1000){
					firstMin-=period;
				}
				//Phase
				g2d.drawString("Phase: "+firstMin+"[sample]",startX+20,startY+40);

				tempcnt = 0;
				absmax = 0;
				absmaxind = 0;
				absmin = 300;
				absminind = 0;
				minstartind = 0;
				minendind = 0;
			}
		}
		
		//draw the original waveform (0->start point)
		/*g2d.setColor(Color.BLUE);
		for(int i=0;i<start-1;i++){
			g2d.drawLine(i*xScaleFactor,heigth-data[i],(i+1)*xScaleFactor,heigth-data[i+1]);
		}*/

		//draw the original waveform (start point->end)
		/*g2d.setColor(Color.BLACK);
		for(int i=0;i<bufferLength-1;i++){
			g2d.drawLine(i*xScaleFactor,heigth-data[i],(i+1)*xScaleFactor,heigth-data[i+1]);
		}*/

		repaint();
	}
}

class SomeAction extends AbstractAction  
{  
	int control;
	PlotFunctionPanel panel;
	boolean pairs;
    public SomeAction(String text, int temp, PlotFunctionPanel pnl, boolean pair )  
    {  
        super( text );  
		control = temp;
		panel = pnl;
		pairs = pair;
    }  
      
    public void actionPerformed( ActionEvent e )  
    {  
        if(pairs){
			panel.pairs = true;
			panel.whichPair = control;
		}else{
			panel.pairs = false;
			panel.whichMote = control;
		}
    }
}  


public class DrawWaveform extends JFrame{

	static int dataCounter = 0;
	static PlotFunctionPanel panel;
	static final int numberOfDataPerMessage = 80;
	static final int firstDataIndex = 10;
	static final int whichWaveformIndex = 8;
	static final int whichPartOfTheWaveformIndex = 9;
	static final int bufferLength = 500;
	static final int maxRssiValue = 25;
	static final int amRadioMsg = 7;
	static final int amIdIndex = 7;
	static final int yScaleFactor = 10;
	static final int xScaleFactor = 2;	
	static final int nodeIdIndex = 4;
	static final int numberOfInfrastMotes = 4;
	static final int numberOfSlots = 12;
	static final int numberOfRx = 6;
	public static DrawWaveform dw;
	public static int waveCnt = 0;
	public static int submenuTemp = 0;

	public void initUI(){
        JMenuBar menubar = new JMenuBar();

        JMenu file = new JMenu("Options");
        file.setMnemonic(KeyEvent.VK_F);

        JMenu mote = new JMenu("Motes:");
		JMenuItem motes[] = new JMenuItem[numberOfInfrastMotes];
		for(int i=0;i<numberOfInfrastMotes;i++){
			motes[i] = new JMenuItem(new SomeAction(i+". mote",i,panel,false));
			mote.add(motes[i]);
		}

        JMenu pairs = new JMenu("Pairs");
		JMenuItem submenus[] = new JMenuItem[numberOfSlots];
		for(int i=0;i<numberOfSlots;i++){
			submenus[i] = new JMenuItem(new SomeAction(i+". slot",i,panel,true));
			pairs.add(submenus[i]);
		}

        file.add(pairs);
        file.addSeparator();
        file.add(mote);
        file.addSeparator();

        menubar.add(file);

        setJMenuBar(menubar);

        setTitle("Plot measures");
        setSize(xScaleFactor*bufferLength, yScaleFactor*maxRssiValue);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
	}

	public void printPacketTimeStamp(PrintStream p, byte[] packet){	
		if(packet[amIdIndex] == amRadioMsg){
			int len = (int)(packet[5] & 0xFF);
			int whichMote = (int)(packet[nodeIdIndex] & 0xFF)-1;
			int whichWaveform = (int)(packet[whichWaveformIndex] & 0xFF);
			int whichPart = (int)(packet[whichPartOfTheWaveformIndex] & 0xFF);
			int startDataCounter = numberOfDataPerMessage*whichPart;
			dataCounter = 0;
			System.out.println("whichMote: "+whichMote+"; whichWaveform: "+whichWaveform+"; whichPart: "+whichPart);
			for(int i=firstDataIndex;i<firstDataIndex+numberOfDataPerMessage && i<len+8;i++){
				panel.data[whichMote][whichWaveform][startDataCounter+dataCounter] = yScaleFactor*(int)(packet[i] & 0xFF);
				dataCounter++;
				if(startDataCounter+dataCounter == bufferLength){					
					break;
				}
			}
			if(/*whichPart == bufferLength/numberOfDataPerMessage && */whichWaveform == numberOfRx-1){
				dw.getContentPane().add(panel);
				dw.pack();
				dw.setVisible(true);
			}
		}
	}

    public static void main(String args[]) throws IOException {
		dw = new DrawWaveform(); 
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

		panel = new PlotFunctionPanel(xScaleFactor*bufferLength, yScaleFactor*maxRssiValue);
		dw.initUI();
		dw.setVisible(true);
		try {
	  		reader.open(PrintStreamMessenger.err);
	  		for (;;) {
	    		byte[] packet = reader.readPacket();
	    		dw.printPacketTimeStamp(System.out, packet);
	    		System.out.flush();
	  		}
		}
		catch (IOException e) {
	    	System.err.println("Error on " + reader.getName() + ": " + e);
		}
    }
}

