import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map.Entry;

import javax.imageio.ImageIO;



class PictureSave {	
	
	public static final int WINDOWS_WIDTH = 1000;
	public static final int WINDOWS_HEIGHT = 1000;
	
	public static final int DIVIDE_WIDTH = 200;
	public static final double PI2 = 2*Math.PI;
	public static final int PERIODSCALE = 3;
	
	private String path;
	private int pictureCnt;	//variable for file name
	private int xScale;
	private int yScale;
	
	public PictureSave(String path) {
		this.path = path;
		yScale = WINDOWS_HEIGHT / DataCollect.MAXSAMPLE;
		pictureCnt = 0;
	}

	public void saveDataToPicture(LinkedHashMap<String, ArrayList<Double>> phase, LinkedHashMap<String, ArrayList<Double>> period){
        BufferedImage img = new BufferedImage(WINDOWS_WIDTH, WINDOWS_HEIGHT, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = img.createGraphics();
        g.fillRect(0, 0, img.getWidth(), img.getHeight());
    	int i = 0,j = 0;

		xScale = (WINDOWS_WIDTH-DIVIDE_WIDTH) / (phase.size()+period.size());
        
        for(Entry<String, ArrayList<Double>> entry : phase.entrySet()) {
        	String key = entry.getKey();
        	ArrayList<Double> node = entry.getValue();
        	for(Double relPhase : node) {
        		double colorScale = relPhase/PI2;
        		if(colorScale >= 1) 
            		g.setColor(new Color(0, 255, 0));
        		else if(colorScale == 0)
        			g.setColor(new Color(0, 0, 0));
        		else 
        			g.setColor(new Color(0, (float)colorScale, 0));
        		g.fillRect(i*xScale, j*yScale, xScale, yScale);
        		j++;
        	}
        	j = 0;
        	i++;
        }
        i = 0;
        for(Entry<String, ArrayList<Double>> entry : period.entrySet()) {
        	ArrayList<Double> node = entry.getValue();
        	for(Double p : node) {
        		double colorScale = (p*PERIODSCALE)/255;
        		if(colorScale >= 1) 
            		g.setColor(new Color(0, 0, 255));
        		else if(colorScale == 0)
        			g.setColor(new Color(255, 0, 0));
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
			boolean ok = ImageIO.write(img, "jpg", new File(path + pictureCnt + ".picture.jpg"));
			pictureCnt++;
//			System.out.println("OK: " + ok);
		} catch(IOException e) {
			e.printStackTrace();
		}
	}
}

class DataCollect {
	
	public static final int MAXSAMPLE = 20;	//the max value of the time domain (y axis)

	PictureSave ps;
	LinkedHashMap<String, ArrayList<Double>> phaseMap;
	LinkedHashMap<String, ArrayList<Double>> periodMap;
	
	public DataCollect(String path) {
		phaseMap = new LinkedHashMap<String, ArrayList<Double>>();
		periodMap = new LinkedHashMap<String, ArrayList<Double>>();

		ps = new PictureSave(path);
	}
	
	public void addElement(double relativePhase, double period, String str) {
		if(phaseMap.get(str) == null) {
			phaseMap.put(str, new ArrayList<Double>());
			periodMap.put(str, new ArrayList<Double>());
		}
		if(phaseMap.get(str).size() >= MAXSAMPLE) {
			ps.saveDataToPicture(phaseMap, periodMap);
			for(Entry<String, ArrayList<Double>> entry : phaseMap.entrySet())
				entry.setValue(new ArrayList<Double>());
			for(Entry<String, ArrayList<Double>> entry : periodMap.entrySet())
				entry.setValue(new ArrayList<Double>());
		} 
		phaseMap.get(str).add(relativePhase);
		periodMap.get(str).add(period);
	}
	
}

public class RelativePhaseMap implements RelativePhaseListener{
	
	public static DataCollect dc;

	
	public RelativePhaseMap(String path) {
		File dir = new File(path);
		dir.mkdirs();
		dc = new DataCollect(path);
	}

	public void relativePhaseReceived(final double relativePhase, final double avgPeriod, int status, int slotId, int rx1, int rx2) {
		final String str = slotId + ":" + rx1 + "," + rx2;
		dc.addElement(relativePhase, avgPeriod, str);	
	}
}
