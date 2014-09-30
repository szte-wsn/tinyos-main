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
	public int[] data;
	static final int yScaleFactor = 15;
	static final int xScaleFactor = 3;
	static final int maxRssiValue = 70;
	static final int bufferLength = 500;
	static final int startTreshold = 5;
	static final int numberOfInfrastMotes = 13;
	
	public PlotFunctionPanel(int width,int heigth){
		this.width = width;
		this.heigth = heigth;
		data = new int[bufferLength];
		setPreferredSize(new Dimension(width, heigth));
	}
	
	public void paintComponent(Graphics g){
		int start=0;
		int temp[] = new int[500];
		int tempcnt = 0;
		int absmin = Integer.MAX_VALUE;
		int absminind = 0;
		int absmax = 0;
		int absmaxind = 0;
		int minstart[] = new int[50];
		int minstartind = 0;
		int minend[] = new int[50];
		int minendind = 0;
		Font font = new Font("font",3,20);
		super.paintComponent(g); 
        Graphics2D g2d = (Graphics2D) g.create();
		g2d.setFont(font);
		int startY = 10;
		int startX = 10;
		g2d.setColor(Color.BLACK);
		g2d.setStroke(new BasicStroke(1, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
		g2d.drawRect(startX,startY,bufferLength*xScaleFactor,maxRssiValue*yScaleFactor);
		//draw horizontal lines
		for(int i=startY;i<startY+maxRssiValue*yScaleFactor;i+=yScaleFactor){
			g2d.drawLine(startX,i,startX+bufferLength*xScaleFactor,i);
		}
		//draw vertical lines
		for(int i=startX;i<startX+bufferLength*xScaleFactor;i+=xScaleFactor){
			g2d.drawLine(i,startY,i,startY+maxRssiValue*yScaleFactor);
		}
		g2d.setColor(Color.RED);
		g2d.setStroke(new BasicStroke(3, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
		for(int i=10;i<bufferLength;i++){
			if(data[i]>startTreshold){
				start=i;
				break;
			}
		}
		//filtering
		for(int i=start+40;i+6<bufferLength-10;i++){
			temp[tempcnt++] = data[i]+2*data[i+1]+3*data[i+2]+4*data[i+3]+3*data[i+4]+2*data[i+5]+data[i+6];
		}
		//search for min and max values
		for(int i=0;i<tempcnt;i++){
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
		int mintresh=absmin+(absmax-absmin)/3;
		//draw a line at the mintresh	
		g2d.setStroke(new BasicStroke(1, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
		g2d.drawLine(startX,startY+maxRssiValue*yScaleFactor-mintresh,startX+bufferLength*xScaleFactor,startY+maxRssiValue*yScaleFactor-mintresh);
		g2d.setStroke(new BasicStroke(3, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
		//finds the minimum regions defined by: values that smaller than mintresh 
		//the minimum regions defined by two values: start and end of the region (minstart,minend)
		int state = 0;
		for(int i=0;i<tempcnt;i++){
			if(state == 0 && temp[i]<mintresh){
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
		if(minendind<4 && minendind>0){
			int firstindex = (minstart[1]+minend[1])/2;
			int secondindex = (minstart[2]+minend[2])/2;
			period = (minstart[2]+minend[2]-minstart[1]-minend[1])/2;
			firstMin = firstindex;
			//draw ovals at the minimum points
			g2d.setColor(Color.GREEN);
			g2d.drawOval(startX+firstindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[firstindex]-2,4,4);
			g2d.drawOval(startX+secondindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[secondindex]-2,4,4);
			g2d.setColor(Color.BLACK);
			//Period: period * 4, because of the filter
			g2d.drawString("Period: "+period+"[sample]",startX+20,startY+20);
		}else if(minendind>=4){
			int firstindex = (minstart[1]+minend[1])/2;
			int secondindex = (minstart[2]+minend[2])/2;	
			int thirdindex = (minstart[3]+minend[3])/2;
			period = (minstart[3]+minend[3]-minstart[1]-minend[1])/4;
			firstMin = firstindex;
			//draw ovals at the minimum points
			g2d.setColor(Color.GREEN);
			g2d.drawOval(startX+firstindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[firstindex]-2,4,4);
			g2d.drawOval(startX+secondindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[secondindex]-2,4,4);
			g2d.drawOval(startX+thirdindex*xScaleFactor-2,startY+maxRssiValue*yScaleFactor-temp[secondindex]-2,4,4);
			//the final period value is the avarage of the two periods
			g2d.setColor(Color.BLACK);
			//Period: period, because of the filter
			g2d.drawString("Period: "+period+"[sample]",startX+20,startY+20);
		}
		if(period!=0)
			firstMin %= period;
		//Phase
		g2d.drawString("Phase: "+firstMin+"[sample]",startX+20,startY+40);

		tempcnt = 0;
		absmax = 0;
		absmaxind = 0;
		absmin = 300;
		absminind = 0;
		minstartind = 0;
		minendind = 0;
		g2d.setColor(Color.BLACK);
		g2d.setStroke(new BasicStroke(1, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
		int space = maxRssiValue*yScaleFactor-500;
		//draw horizontal lines
		for(int i=startY+space;i<startY+space+maxRssiValue*yScaleFactor;i+=yScaleFactor){
			g2d.drawLine(startX,i,startX+bufferLength*xScaleFactor,i);
		}
		//draw vertical lines
		for(int i=startX;i<startX+bufferLength*xScaleFactor;i+=xScaleFactor){
			g2d.drawLine(i,startY+space,i,startY+space+maxRssiValue*yScaleFactor);
		}
		//draw the original waveform (0->start point)
		g2d.setColor(Color.RED);
		g2d.setStroke(new BasicStroke(3, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
		for(int i=0;i<start-1;i++){
			g2d.drawLine(startX+i*xScaleFactor,startY+space+maxRssiValue*yScaleFactor-data[i],startX+(i+1)*xScaleFactor,startY+space+maxRssiValue*yScaleFactor-data[i+1]);
		}

		//draw the original waveform (start point->end)
		g2d.setColor(Color.BLACK);
		for(int i=0;i<bufferLength-1;i++){
			g2d.drawLine(startX+i*xScaleFactor,startY+space+maxRssiValue*yScaleFactor-data[i],startX+(i+1)*xScaleFactor,startY+space+maxRssiValue*yScaleFactor-data[i+1]);
		}

		repaint();
	}
}

/*class SomeAction extends AbstractAction  
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
} */ 


public class WaveformProcess extends JFrame{
	public static WaveformProcess dw;
	public static int submenuTemp = 0;
	public static PlotFunctionPanel panel;
	public static String filename;


	public void initUI(){
        /*JMenuBar menubar = new JMenuBar();

        JMenu file = new JMenu("Options");
        file.setMnemonic(KeyEvent.VK_F);

        JMenu mote = new JMenu("Motes:");
		JMenuItem motes[] = new JMenuItem[numberOfInfrastMotes];
		for(int i=0;i<numberOfInfrastMotes;i++){
			motes[i] = new JMenuItem(new SomeAction((i+1)+". mote",i,panel,false));
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

        setJMenuBar(menubar);*/

        setTitle("Plot measures");
        setSize(1600, 850);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
	}

    public static void main(String args[]) throws IOException {
		dw = new WaveformProcess(); 
        if (args.length == 1) {
        	filename = args[0];
        }
		else{
	    	System.err.println("usage: java WaveformProcess filename");
	    	System.exit(2);
		}
		panel = new PlotFunctionPanel(1600, 1000);
		dw.initUI();
		dw.setVisible(true);
		BufferedReader br = new BufferedReader(new FileReader(filename));
    	try {
    		for(int i=0;i<500;i++){
    			panel.data[i]=Integer.parseInt(br.readLine())*4;
    		}
    	} finally {
        	br.close();
    	}
    	dw.getContentPane().add(panel);
		dw.pack();
		dw.setVisible(true);
    }
}

