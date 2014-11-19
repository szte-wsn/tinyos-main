import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map.Entry;

import javax.imageio.ImageIO;
import javax.swing.DefaultListModel;
import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JScrollPane;

public class RelativePhaseMap implements RelativePhaseListener{
	
	class PictureSave {	
		public static final int MAXSAMPLE = 5;	//the max value of the time domain (y axis)
		private static final int STORE_LAST_N_MAXSAMPLE = 50; //displayed number of maxsample block
		public static final int WINDOWS_WIDTH = 1000;
		public static final int WINDOWS_HEIGHT = 50;
		public static final int DIVIDE_WIDTH = 200;
		public static final double PI2 = 2*Math.PI;
		public static final int PERIODSCALE = 3;
		private static final int NO_DATA = 1000;	//default status
		
		class StoreType {
			public int status;
			public double data;
			public StoreType(int status, double data) {
				this.status = status;
				this.data = data;
			}
			
			public ArrayList<StoreType> defaultArrayList () {
				ArrayList<StoreType> list = new ArrayList<StoreType>();
				for(int i=0; i<MAXSAMPLE; i++) 
					list.add(new StoreType(NO_DATA, 0));
				
				return list;
			}
		}
		
		LinkedHashMap<String, ArrayList<StoreType>> phaseMap;
		LinkedHashMap<String, ArrayList<StoreType>> periodMap;
		private String path;
		private int pictureCnt;	//variable for file name
		private int xScale;
		private int yScale;
		
		JFrame frame;
		DefaultListModel<ImageIcon> listModel;
		JList<ImageIcon> lsm;
		JScrollPane jsp;
		int[] otherNode; 
		int lastRX;		//which rx's received last
		int counter;	//how many rows put in Maps 
		boolean saveToFile;	//create picture or not
		
		public PictureSave(String path, boolean saveToFile) {
			if(saveToFile) 
				this.path = path;
			this.saveToFile = saveToFile;
			phaseMap = new LinkedHashMap<String, ArrayList<StoreType>>();
			periodMap = new LinkedHashMap<String, ArrayList<StoreType>>();
			yScale = WINDOWS_HEIGHT / MAXSAMPLE;
			pictureCnt = 0;
		}
		
		private void initalize(int refNode, int[] otherNode) {
			for(int i : otherNode) {
				String str = refNode + "," + i;
				phaseMap.put(str, new StoreType(NO_DATA, 0).defaultArrayList());
				periodMap.put(str, new StoreType(NO_DATA, 0).defaultArrayList());
			}
			xScale = (WINDOWS_WIDTH-DIVIDE_WIDTH) / (otherNode.length*2);
			lastRX = otherNode[0];
			counter = 0;
			
			listModel = new DefaultListModel<ImageIcon>();
			lsm=new JList<ImageIcon>(listModel);
			jsp = new JScrollPane(lsm);
			frame = new JFrame();
			JLabel label;
			for(int i=0; i<otherNode.length; i++) {
				label = new JLabel(otherNode[i] + "");
				label.setFont(new Font("Serif", Font.BOLD, 10));
				label.setBounds(i*xScale, 0, 100,10);
				frame.add(label);
				label = new JLabel(otherNode[i] + "");
				label.setFont(new Font("Serif", Font.BOLD, 10));
				label.setBounds(otherNode.length*xScale + i*xScale + DIVIDE_WIDTH, 0, 100,10);
				frame.add(label);
			}
			frame.add(jsp);
			frame.setMinimumSize(new Dimension(WINDOWS_WIDTH, 500));
			frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		    frame.pack();
		    frame.setVisible(true);
		}
		
		public void addElement(double relativePhase, double period, int status, int rx1, int rx2) {
			if(lastRX > rx2) 
				counter++;
			lastRX = rx2;
			String str = rx1 + "," + rx2;
			if(counter >= MAXSAMPLE) {
				saveDataToPicture(phaseMap, periodMap);
				for(Entry<String, ArrayList<StoreType>> entry : phaseMap.entrySet())
					entry.setValue(new StoreType(NO_DATA, 0).defaultArrayList());
				for(Entry<String, ArrayList<StoreType>> entry : periodMap.entrySet())
					entry.setValue(new StoreType(NO_DATA, 0).defaultArrayList());
				counter = 0;
			} 
			phaseMap.get(str).set(counter, new StoreType(status, relativePhase));
			periodMap.get(str).set(counter, new StoreType(status, period));
		}

		public void saveDataToPicture(LinkedHashMap<String, ArrayList<StoreType>> phase, LinkedHashMap<String, ArrayList<StoreType>> period){
	        BufferedImage img = new BufferedImage(WINDOWS_WIDTH, WINDOWS_HEIGHT, BufferedImage.TYPE_INT_RGB);
	        Graphics2D g = img.createGraphics();
	        g.fillRect(0, 0, img.getWidth(), img.getHeight());
	    	int i = 0,j = 0;
        	int k = 0;
	        for(Entry<String, ArrayList<StoreType>> entry : phase.entrySet()) {
	        	ArrayList<StoreType> node = entry.getValue();
	        	for(StoreType relPhase : node) {
	        		double colorScale = relPhase.data/PI2;
	        		Color c = setColor(relPhase.status);
	        		if(c != Color.BLACK)
	        			g.setColor(c);
	        		else 
	        			g.setColor(new Color(0, (float)colorScale, 0));
	        		g.fillRect(i*xScale, j*yScale, xScale, yScale);
	        		j++;
	        	}
        		k++;
	        	j = 0;
	        	i++;
	        }
	        i = 0;
	        for(Entry<String, ArrayList<StoreType>> entry : period.entrySet()) {
	        	ArrayList<StoreType> node = entry.getValue();
	        	for(StoreType p : node) {
	        		double colorScale = (p.data*PERIODSCALE)/255;
	        		Color c = setColor(p.status);
	        		if(c != Color.BLACK)
	        			g.setColor(c);
	        		else 
	            		g.setColor(new Color(0, (float)colorScale, 0));
	        		g.fillRect(phase.size()*xScale + i*xScale + DIVIDE_WIDTH, j*yScale, xScale, yScale);
	        		j++;
	        	}
	        	j = 0;
	        	i++;
	        }
			g.dispose();
			try {
				if(listModel.size()>=STORE_LAST_N_MAXSAMPLE) {
					listModel.removeElementAt(STORE_LAST_N_MAXSAMPLE-1);
					listModel.add(0,new ImageIcon(img));
				} else
					listModel.add(0,new ImageIcon(img));
				frame.repaint();
				if(saveToFile) {
					ImageIO.write(img, "jpg", new File(path + pictureCnt + ".picture.jpg"));
					pictureCnt++;
				}
			} catch(IOException e) {
				e.printStackTrace();
			}
		}
		
		public Color setColor(int status) {
			if(status == SlotMeasurement.ERR_START_NOT_FOUND) 
	    		return Color.RED;
			else if(status == SlotMeasurement.ERR_SMALL_MINMAX_RANGE)
				return Color.BLUE;
			else if(status == SlotMeasurement.ERR_FEW_ZERO_CROSSINGS)
				return Color.GRAY;
			else if(status == SlotMeasurement.ERR_LARGE_PERIOD)
				return Color.YELLOW;
			else if(status == SlotMeasurement.ERR_PERIOD_MISMATCH)
				return Color.ORANGE;
			else if(status == SlotMeasurement.ERR_ZERO_PERIOD)
				return Color.PINK;
			else if(status == SlotMeasurement.ERR_CALCULATION_TIMEOUT)
				return Color.CYAN;
			else if(status == SlotMeasurement.ERR_NO_MEASUREMENT)
				return Color.MAGENTA;
			else if(status == RelativePhaseCalculator.STATUS_PERIOD_DIFF_LARGE)
				return Color.DARK_GRAY;
			else if(status == NO_DATA) 
				return Color.WHITE;
			else
				return Color.BLACK;
		}
	}
	
	private PictureSave ps;

	public RelativePhaseMap(String path, int refNode, int[] otherNode, boolean saveToFile) {
		if(saveToFile) {
			File dir = new File(path);
			dir.mkdirs();
		}
		ps = new PictureSave(path, saveToFile);
		ps.initalize(refNode,otherNode);
	}

	public void relativePhaseReceived(final double relativePhase, final double avgPeriod, int status, int slotId, int rx1, int rx2) {
		ps.addElement(relativePhase, avgPeriod, status, rx1, rx2);	
	}

}
