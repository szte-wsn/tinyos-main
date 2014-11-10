import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map.Entry;

import javax.imageio.ImageIO;

public class RelativePhaseMap implements RelativePhaseListener{
	
	class PictureSave {	
		public static final int MAXSAMPLE = 5;	//the max value of the time domain (y axis)
		public static final int WINDOWS_WIDTH = 1000;
		public static final int WINDOWS_HEIGHT = 1000;
		public static final int DIVIDE_WIDTH = 200;
		public static final double PI2 = 2*Math.PI;
		public static final int PERIODSCALE = 3;
		
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
		
		public PictureSave(String path) {
			this.path = path;
			phaseMap = new LinkedHashMap<String, ArrayList<StoreType>>();
			periodMap = new LinkedHashMap<String, ArrayList<StoreType>>();
			yScale = WINDOWS_HEIGHT / MAXSAMPLE;
			pictureCnt = 0;
		}
		
		public void addElement(double relativePhase, double period, String str, int status) {
			if(phaseMap.get(str) == null) {
				phaseMap.put(str, new ArrayList<StoreType>());
				periodMap.put(str, new ArrayList<StoreType>());
			}
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
	    	int i = 0,j = 0;

			xScale = (WINDOWS_WIDTH-DIVIDE_WIDTH) / (phase.size()+period.size());		
			
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
				ImageIO.write(img, "jpg", new File(path + pictureCnt + ".picture.jpg"));
				pictureCnt++;
			} catch(IOException e) {
				e.printStackTrace();
			}
		}
		
		public Color setColor(int status) {
			if(status == RelativePhaseCalculator.ERR_START_NOT_FOUND) 
	    		return Color.RED;
			else if(status == RelativePhaseCalculator.ERR_SMALL_MINMAX_RANGE)
				return Color.BLUE;
			else if(status == RelativePhaseCalculator.ERR_FEW_ZERO_CROSSINGS)
				return Color.GRAY;
			else if(status == RelativePhaseCalculator.ERR_LARGE_PERIOD)
				return Color.YELLOW;
			else if(status == RelativePhaseCalculator.ERR_PERIOD_MISMATCH)
				return Color.ORANGE;
			else if(status == RelativePhaseCalculator.ERR_ZERO_PERIOD)
				return Color.PINK;
			else
				return Color.BLACK;
		}
	}
	
	private PictureSave ps;

	public RelativePhaseMap(String path) {
		File dir = new File(path);
		dir.mkdirs();
		ps = new PictureSave(path);
	}

	public void relativePhaseReceived(final double relativePhase, final double avgPeriod, int status, int slotId, int rx1, int rx2) {
		final String str = slotId + ":" + rx1 + "," + rx2;
		ps.addElement(relativePhase, avgPeriod, str, status);	
	}

}
