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
import java.util.HashMap;
import java.util.LinkedList;

import javax.imageio.ImageIO;
import javax.swing.DefaultListModel;
import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.SwingUtilities;

public class RelativePhaseMap implements RelativePhaseListener{
	
	class PictureSave {	
		public static final int MAXSAMPLE = 3;	//the max value of the time domain (y axis)
		private static final int STORE_LAST_N_MAXSAMPLE = 300; //displayed number of maxsample block
		public static final int WINDOWS_WIDTH = 1000;
		public static final int WINDOWS_HEIGHT = 800;
		private static final int COLOR_WINDOW_WIDTH = 300;
		private static final int COLOR_WINDOW_HEIGHT = 350;
		public static final int DIVIDE_WIDTH = 200;
		public static final int PERIODSCALE = 80;
		private static final int FONT_SIZE = 10;
		private static final int LINE_PER_FILE=100;
		
		class StoreType {
			public int status;
			public double phase;
			public double period;
			public StoreType(int status, double period, double phase) {
				this.status = status;
				this.period = period;
				this.phase = phase;
			}
		}
		
		private ArrayList<HashMap<Integer, StoreType>> data = new ArrayList<HashMap<Integer, StoreType>>();
		private HashMap<Integer, StoreType> currentLine = new HashMap<Integer, StoreType>();
		
		
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
		boolean rx1isReference;
		
		PaintThread paint;
		
		
		public PictureSave(String path, boolean saveToFile, boolean summarizeData) {
			if(saveToFile) 
				this.path = path;
			this.saveToFile = saveToFile;
			this.summarizeData = summarizeData;
			pictureCnt = 0;
			yScale = WINDOWS_HEIGHT / 60;
		}
		
		private void initalize(int refNode, 	int[] otherNode) {
			xScale = (WINDOWS_WIDTH-DIVIDE_WIDTH) / (otherNode.length*2);
			listModel = new DefaultListModel<ImageIcon>();
			lsm = new JList<ImageIcon>(listModel);
			lsm.setFixedCellHeight(yScale);
			jsp = new JScrollPane(lsm);
			jsp.setPreferredSize(new Dimension(WINDOWS_WIDTH,WINDOWS_HEIGHT));
			frame = new JFrame("PhaseMap");
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
			frame.setMinimumSize(new Dimension(WINDOWS_WIDTH+COLOR_WINDOW_WIDTH+50, WINDOWS_HEIGHT));
			frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		    frame.pack();
		    frame.setVisible(true);
		    
		    paint = new PaintThread(otherNode);
		    paint.start();
		}
		
		public void addElement(double relativePhase, double period, int status, int reference, int other, int slotId) {
			if( currentLine.containsKey(other) ){ //new line 
				synchronized (paint) {
					data.add(currentLine);
					if( data.size() >= MAXSAMPLE )
						paint.notify();
				}
				currentLine = new HashMap<Integer, StoreType>();
			}
			StoreType value = new StoreType(status, period, relativePhase);
			currentLine.put(other, value);
		}
		
		public class PaintThread extends Thread	{
			private BufferedImage imageFile = null;
			private Graphics2D filegraphics = null;
			private int fileLines = 0; 
			
			private int[] measuredNodes;
			private int periodOffset;
	        
			public PaintThread(int[] measuredNodes){
				this.measuredNodes = measuredNodes;
				this.periodOffset = measuredNodes.length*xScale + DIVIDE_WIDTH;
				imageFile = new BufferedImage(WINDOWS_WIDTH, yScale*LINE_PER_FILE, BufferedImage.TYPE_INT_RGB);
				filegraphics = imageFile.createGraphics();
			}
			
			LinkedList<ImageIcon> icons = new LinkedList<>();
			
			private void saveImage(Graphics2D g, BufferedImage img) {
				g.dispose();
				synchronized(icons){
					icons.add(new ImageIcon(img));
				}
				
				Runnable addList = new Runnable() {
					public void run() {
						synchronized(icons){
							while(icons.size() > 0){
				    			listModel.add(0, icons.getFirst());
				    			icons.removeFirst();
				    		}
				    	}
				        while(listModel.size()>STORE_LAST_N_MAXSAMPLE){
				        	listModel.remove(listModel.size()-1);
				        }
				    }
				};
				SwingUtilities.invokeLater(addList);
				
				if(saveToFile) {
					filegraphics.drawImage(img, 0, fileLines*yScale, borderPanel);
					if( ++fileLines>LINE_PER_FILE ){
						try {
							ImageIO.write(imageFile, "png", new File(String.format("%s%04d.picture.png", path, pictureCnt)));
						} catch(IOException e) {
							e.printStackTrace();
						}
						pictureCnt++;
						fileLines = 0;
						imageFile = new BufferedImage(WINDOWS_WIDTH, yScale*LINE_PER_FILE, BufferedImage.TYPE_INT_RGB);
						filegraphics = imageFile.createGraphics();
					}
				}
			}
			
			@SuppressWarnings("unchecked")
			@Override
		    public void run()
		    {
				ArrayList<HashMap<Integer,StoreType>> dataClone;
				while(true){
					synchronized (this) {
						dataClone =  (ArrayList<HashMap<Integer,RelativePhaseMap.PictureSave.StoreType>>) data.clone();
						data = new ArrayList<HashMap<Integer, StoreType>>();
					}
			        
			        if ( summarizeData ){
			        	BufferedImage img = new BufferedImage(WINDOWS_WIDTH, yScale, BufferedImage.TYPE_INT_RGB);
						Graphics2D g = img.createGraphics();
						g.fillRect(0, 0, img.getWidth(), img.getHeight());
				        double avgPeriod[] = new double[measuredNodes.length];
				        double avgPhase[] = new double[measuredNodes.length];
				        int avg_num[] = new int[measuredNodes.length];
				        for(int i=0;i<measuredNodes.length;i++){
				        	avgPeriod[i] = 0.0;
				        	avgPhase[i] = 0.0;
				        	avg_num[i] = 0;
				        }
				        for(HashMap<Integer, StoreType> line:dataClone){
				        	for(int i=0;i<measuredNodes.length;i++){
				        		StoreType element = line.get(measuredNodes[i]);
				        		if( element.status == RelativePhaseCalculator.STATUS_OK ){
				        			avgPeriod[i]+=element.period;
				        			avgPhase[i]+=element.phase;
				        			avg_num[i]++;
				        		}
				        	}
				        }
				        for(int i=0;i<measuredNodes.length;i++){
				        	if(avg_num[i] != 0 || avgPeriod[i] != 0.0) {
				        		avgPeriod[i] /= avg_num[i];
				        		avgPhase[i] /= avg_num[i];
				        		avgPeriod[i] /= PERIODSCALE; //scale them to 0-1 interval
				        		avgPhase[i] /= Math.PI*2;
				        		g.setColor(new Color((float)avgPhase[i], (float)avgPhase[i], (float)avgPhase[i]));
				        		g.fillRect(i*xScale, 0, xScale, img.getHeight());
								g.setColor(new Color((float)avgPeriod[i], (float)avgPeriod[i], (float)avgPeriod[i]));
								g.fillRect(periodOffset + i*xScale, 0, xScale, img.getHeight());
				        	} else {
								g.setColor(Color.RED);
								g.fillRect(i*xScale, 0, xScale, img.getHeight());
								g.fillRect(periodOffset + i*xScale, 0, xScale, img.getHeight());
				        	}
				        }
				        saveImage(g, img);
			        } else {
			        	for(HashMap<Integer, StoreType> line:dataClone){
			        		BufferedImage img = new BufferedImage(WINDOWS_WIDTH, yScale, BufferedImage.TYPE_INT_RGB);
							Graphics2D g = img.createGraphics();
							g.fillRect(0, 0, img.getWidth(), img.getHeight());
				        	for(int i=0;i<measuredNodes.length;i++){
				        		StoreType element = line.get(measuredNodes[i]);
				        		if( element != null && element.status == RelativePhaseCalculator.STATUS_OK ){
				        			float colorScale = (float) (element.phase / (Math.PI*2));
				        			g.setColor(new Color(colorScale, colorScale, colorScale));
				        			g.fillRect(i*xScale, 0, xScale, img.getHeight());
				        			colorScale = (float) (element.period / PERIODSCALE);
				        			g.setColor(new Color(colorScale, colorScale, colorScale));
				        			g.fillRect(periodOffset + i*xScale, 0, xScale, img.getHeight());
			        			} else {
		        					Color c = setColor(element.status);
			        				g.setColor(c);
			        				g.fillRect(i*xScale, 0, xScale, yScale);
									g.fillRect(periodOffset + i*xScale, 0, xScale, yScale);
		        				}
				        	}    
				        	saveImage(g, img);
				        }
					}
					
					try {
						synchronized (this) {
							this.wait();
						}
					} catch (InterruptedException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
				}
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

	public void relativePhaseReceived(final double relativePhase, final double avgPeriod, int status, int slotId, int reference, int other) {
		ps.addElement(relativePhase, avgPeriod, status, reference, other, slotId);	
	}

}