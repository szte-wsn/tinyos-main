import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map.Entry;

import javax.imageio.ImageIO;
import javax.swing.DefaultListModel;
import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JPanel;
import javax.swing.JScrollPane;

public class RelativePhaseMap implements RelativePhaseListener{
	
	class PictureSave {	
		public static final int MAXSAMPLE = 20;	//the max value of the time domain (y axis)
		private static final int STORE_LAST_N_MAXSAMPLE = 20; //displayed number of maxsample block
		public static final int WINDOWS_WIDTH = 1000;
		public static final int WINDOWS_HEIGHT = MAXSAMPLE*2;
		private static final int COLOR_WINDOW_WIDTH = 300;
		private static final int COLOR_WINDOW_HEIGHT = 350;
		public static final int DIVIDE_WIDTH = 200;
		public static final double PI2 = 2*Math.PI;
		public static final int PERIODSCALE = 3;
		private static final int FONT_SIZE = 10;
		
		class StoreType {
			public int status;
			public double data;
			public StoreType(int status, double data) {
				this.status = status;
				this.data = data;
			}
		}
		
		LinkedHashMap<String, ArrayList<StoreType>> phaseMap;
		LinkedHashMap<String, ArrayList<StoreType>> periodMap;
		private String path;
		private int pictureCnt;	//variable for file name
		private int xScale;
		private int yScale;
		
		JFrame frame;
		JPanel borderPanel;
		JScrollPane jsp;
		JScrollPane colorPanel;
		DefaultListModel<ImageIcon> listModel;
		JList<ImageIcon> lsm;
		int[] otherNode; 
		boolean saveToFile;	//create picture or not
		boolean summarizeData;	//summarize data or not
		
		public PictureSave(String path, boolean saveToFile, boolean summarizeData) {
			if(saveToFile) 
				this.path = path;
			this.saveToFile = saveToFile;
			this.summarizeData = summarizeData;
			phaseMap = new LinkedHashMap<String, ArrayList<StoreType>>();
			periodMap = new LinkedHashMap<String, ArrayList<StoreType>>();
			yScale = WINDOWS_HEIGHT / MAXSAMPLE;
			pictureCnt = 0;
		}
		
		private void initalize(int refNode, 	int[] otherNode) {
			for(int i : otherNode) {
				String str = refNode + "," + i;
				phaseMap.put(str, new ArrayList<StoreType>());
				periodMap.put(str, new ArrayList<StoreType>());
			}
			xScale = (WINDOWS_WIDTH-DIVIDE_WIDTH) / (otherNode.length*2);
			listModel = new DefaultListModel<ImageIcon>();
			lsm = new JList<ImageIcon>(listModel);
			lsm.setFixedCellHeight(WINDOWS_HEIGHT);
			jsp = new JScrollPane(lsm);
			jsp.setPreferredSize(new Dimension(WINDOWS_WIDTH,WINDOWS_HEIGHT));
			frame = new JFrame();
			borderPanel = new JPanel(new BorderLayout());
		//write mote numbers
			JLabel label;
			JPanel labelPanel = new JPanel();
			labelPanel.setPreferredSize(new Dimension(WINDOWS_WIDTH,FONT_SIZE*2));
			for(int i=0; i<otherNode.length; i++) {
				label = new JLabel(otherNode[i] + "");
				label.setFont(new Font("Serif", Font.BOLD, FONT_SIZE));
				label.setBounds(i*xScale, 0, 100, FONT_SIZE);
				borderPanel.add(label,BorderLayout.NORTH);
				label = new JLabel(otherNode[i] + "");
				label.setFont(new Font("Serif", Font.BOLD, FONT_SIZE));
				label.setBounds(otherNode.length*xScale + i*xScale + DIVIDE_WIDTH, 0, 100, FONT_SIZE);
				borderPanel.add(label,BorderLayout.NORTH);
			}
			label = new JLabel(" ");
			label.setFont(new Font("Serif", Font.BOLD, FONT_SIZE));
			label.setBounds(0, 0, 100, FONT_SIZE);
			borderPanel.add(label,BorderLayout.NORTH);

		//write color legends
			BufferedImage colorImg = new BufferedImage(COLOR_WINDOW_WIDTH, COLOR_WINDOW_HEIGHT, BufferedImage.TYPE_INT_RGB);
			JLabel colorImgLabel = new JLabel(new ImageIcon(colorImg));
	        Graphics g = colorImg.getGraphics();
	        g.setColor(Color.WHITE);
	        g.fillRect(0, 0, colorImg.getWidth(), colorImg.getHeight());
            ArrayList<Integer> statusCodes = getAllStatusCode();
            ArrayList<String> statusNames = getAllStatusName();
	        for(int i=0; i<statusCodes.size(); i++) {
	        	g.setColor(setColor(statusCodes.get(i)));
	        	g.fillRect(0, FONT_SIZE+i*30, 100, 20);
	        	g.setColor(Color.BLACK);
	        	g.drawString(statusNames.get(i), 100+10, FONT_SIZE+i*30+10);
	        }
	        g.dispose();
	        
			borderPanel.add(jsp,BorderLayout.WEST);
			borderPanel.add(colorImgLabel,BorderLayout.EAST);
			frame.add(borderPanel);
			frame.setMinimumSize(new Dimension(WINDOWS_WIDTH+COLOR_WINDOW_WIDTH+50, 500));
			frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		    frame.pack();
		    frame.setVisible(true);
		}
		
		public void addElement(double relativePhase, double period, int status, int rx1, int rx2, int slotId) {
			String str = rx1 + "," + rx2;
			if(phaseMap.get(str).size() >= MAXSAMPLE) {
				saveDataToPicture(phaseMap, periodMap);
				for(Entry<String, ArrayList<StoreType>> entry : phaseMap.entrySet())
					entry.setValue(new ArrayList<StoreType>());
				for(Entry<String, ArrayList<StoreType>> entry : periodMap.entrySet())
					entry.setValue(new ArrayList<StoreType>());
			}
			phaseMap.get(str).add(new StoreType(status, relativePhase));
			periodMap.get(str).add(new StoreType(status, period));
		}

		public void saveDataToPicture(LinkedHashMap<String, ArrayList<StoreType>> phase, LinkedHashMap<String, ArrayList<StoreType>> period){
	        BufferedImage img = new BufferedImage(WINDOWS_WIDTH, WINDOWS_HEIGHT, BufferedImage.TYPE_INT_RGB);
	        Graphics2D g = img.createGraphics();
	        g.fillRect(0, 0, img.getWidth(), img.getHeight());
	    	int i = 0;
	    	int j = MAXSAMPLE-1;
	        double avg = 0.0;
	        int avg_num = 0;
	        for(Entry<String, ArrayList<StoreType>> entry : phase.entrySet()) {
	        	ArrayList<StoreType> node = entry.getValue();
	        	if(summarizeData) {
			        avg = 0.0;
			        avg_num = 0;
		        	for(StoreType relPhase : node) {
		        		if(relPhase.status == RelativePhaseCalculator.STATUS_OK) {
		        			avg += relPhase.data/PI2;
		        			avg_num++;
		        		}
		        	}
		        	if(avg_num != 0 || avg != 0.0) {
		        		avg /= avg_num;
						g.setColor(new Color((float)avg, (float)avg, (float)avg));
		        	}
		        	else
						g.setColor(Color.RED);
					g.fillRect(i*xScale, 0, xScale, WINDOWS_HEIGHT);
		        	i++;
	        	} else {
	        		for(StoreType relPhase : node) {
	        			if(relPhase.status == RelativePhaseCalculator.STATUS_OK) {
	        				double colorScale = relPhase.data/PI2;
		        			g.setColor(new Color((float)colorScale, (float)colorScale, (float)colorScale));
	        			} else {
        					Color c = setColor(relPhase.status);
	        				g.setColor(c);
        				}
		        		g.fillRect(i*xScale, j*yScale, xScale, yScale);
		        		j--;
		        	}
		        	j = MAXSAMPLE-1;
		        	i++;
	        	}	        		
	        }
	        i = 0;
	        for(Entry<String, ArrayList<StoreType>> entry : period.entrySet()) {
				ArrayList<StoreType> node = entry.getValue();
	        	if(summarizeData) {
		        	avg = 0.0;
					avg_num = 0;
					for(StoreType p : node) {
						if(p.status == RelativePhaseCalculator.STATUS_OK) {
							avg += (p.data*PERIODSCALE)/255;
							avg_num++;
						}
					}
		        	if(avg_num != 0  || avg != 0.0) {
		        		avg /= avg_num;
						g.setColor(new Color((float)avg, (float)avg, (float)avg));
		        	}
		        	else
						g.setColor(Color.RED);
	        		g.fillRect(phase.size()*xScale + i*xScale + DIVIDE_WIDTH, 0, xScale, WINDOWS_HEIGHT);
					i++;
	        	} else {
	        		for(StoreType p : node) {
						if(p.status == RelativePhaseCalculator.STATUS_OK) {
							double colorScale = (p.data*PERIODSCALE)/255;
		            		g.setColor(new Color((float)colorScale, (float)colorScale, (float)colorScale));
						} else {
							Color c = setColor(p.status);
		        			g.setColor(c);
						}
		        		g.fillRect(phase.size()*xScale + i*xScale + DIVIDE_WIDTH, j*yScale, xScale, yScale);
		        		j--;
		        	}
		        	j = MAXSAMPLE-1;
		        	i++;
	        	}
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
				return new Color(153,0,153);
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
				return Color.GREEN;
			else if(status == RelativePhaseCalculator.STATUS_NO_DATA)
				return new Color(153,153,255);
			else if(status == RelativePhaseCalculator.STATUS_NO_REFERENCE)
				return new Color(153,255,153);
			else
				return Color.BLACK;
		}
		
		public ArrayList<Integer> getAllStatusCode() {
			ArrayList<Integer> statusCodes = new ArrayList<Integer>();
			statusCodes.add(SlotMeasurement.ERR_START_NOT_FOUND);
			statusCodes.add(SlotMeasurement.ERR_SMALL_MINMAX_RANGE);
			statusCodes.add(SlotMeasurement.ERR_FEW_ZERO_CROSSINGS);
			statusCodes.add(SlotMeasurement.ERR_LARGE_PERIOD);
			statusCodes.add(SlotMeasurement.ERR_PERIOD_MISMATCH);
			statusCodes.add(SlotMeasurement.ERR_ZERO_PERIOD);
			statusCodes.add(SlotMeasurement.ERR_CALCULATION_TIMEOUT);
			statusCodes.add(SlotMeasurement.ERR_NO_MEASUREMENT);
			statusCodes.add(RelativePhaseCalculator.STATUS_PERIOD_DIFF_LARGE);
			statusCodes.add(RelativePhaseCalculator.STATUS_NO_DATA);
			statusCodes.add(RelativePhaseCalculator.STATUS_NO_REFERENCE);
			return statusCodes;
		}
		
		public ArrayList<String> getAllStatusName() {
			ArrayList<String> statusNames = new ArrayList<String>();
			statusNames.add("ERR_START_NOT_FOUND");
			statusNames.add("ERR_SMALL_MINMAX_RANGE");
			statusNames.add("ERR_FEW_ZERO_CROSSINGS");
			statusNames.add("ERR_LARGE_PERIOD");
			statusNames.add("ERR_PERIOD_MISMATCH");
			statusNames.add("ERR_ZERO_PERIOD");
			statusNames.add("ERR_CALCULATION_TIMEOUT");
			statusNames.add("ERR_NO_MEASUREMENT");
			statusNames.add("STATUS_PERIOD_DIFF_LARGE");
			statusNames.add("STATUS_NO_DATA");
			statusNames.add("STATUS_NO_REFERENCE");			
			return statusNames;

		}
	}
	
	private PictureSave ps;

	public RelativePhaseMap(String path, int refNode, int[] otherNode, boolean saveToFile, boolean summarizeData) {
		if(saveToFile) {
			File dir = new File(path);
			dir.mkdirs();
		}
		ps = new PictureSave(path, saveToFile, summarizeData);
		ps.initalize(refNode, otherNode);
	}

	public void relativePhaseReceived(final double relativePhase, final double avgPeriod, int status, int slotId, int rx1, int rx2) {
		ps.addElement(relativePhase, avgPeriod, status, rx1, rx2, slotId);	
	}

}