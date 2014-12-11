import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Component;
import java.awt.GradientPaint;
import java.awt.Graphics2D;
import java.awt.GridLayout;
import java.awt.Paint;
import java.awt.Shape;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import javax.swing.JPanel;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.ValueAxis;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.XYPlot;
import org.jfree.chart.renderer.xy.XYLineAndShapeRenderer;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;
import org.jfree.ui.ApplicationFrame;
import org.jfree.ui.RefineryUtilities;


public class DrawRelativePhase implements RelativePhaseListener{

	class AppFrame extends ApplicationFrame {
		private static final long serialVersionUID = 425044847909613911L;
		JPanel panel;
		
		public AppFrame(String appTitle) {
			super(appTitle);
			panel = new JPanel(new GridLayout(3,1));
		}
		
		public void addChartPanel(ChartPanel chart) {
			this.setContentPane(panel);
			panel.add(chart);
		}
	}
	
	class Chart{
		
		static final int MAXSAMPLES = 1;
		static final int DRAW_LAST_N_VALUE = 150;
		static final double PI = Math.PI;
		static final double PI2 = 2*Math.PI;
		
		protected class StoreType {
			public double phase;
			public double period;
			public int status;
			public StoreType(double period, double phase, int status) {
				this.period = period;
				this.phase = phase;
				this.status = status;
			}
		}
		
		protected ChartPanel chartPanel;
		public JFreeChart chart;
		protected XYSeriesCollection dataSet; 
		protected ArrayList<String> series;	//store the curves dataset index. String = "slotId:rx1,rx2"
		protected HashMap<String,StoreType> currentLine;
		protected ArrayList<HashMap<String,StoreType>> data;
		protected PaintThread paint;
		protected String tit; 
		
		public Chart(String chartTitle, AppFrame appframe, String xAxis, String yAxis) {
			series = new ArrayList<String>();
			dataSet = new XYSeriesCollection();
	        JFreeChart chart = createChart(chartTitle, xAxis, yAxis, dataSet);
	        chartPanel = new ChartPanel(chart); 
	        chartPanel.setPreferredSize(new java.awt.Dimension(500, 270));
	        appframe.addChartPanel(chartPanel);
	        tit = chartTitle;
	        currentLine = new HashMap<String, StoreType>();
	        data = new ArrayList<HashMap<String,StoreType>>();
		}
		
		public void initalize() {
	        paint = new PaintThread();
	        paint.setName(tit);
	        paint.start();
		}
		
	    protected JFreeChart createChart(String chartTitle, String xAxis, String yAxis, XYSeriesCollection dataSet) {
	    	chart = ChartFactory.createXYLineChart(
				chartTitle,
				xAxis,
				yAxis,
				dataSet,
				PlotOrientation.VERTICAL,
				true, true, false);  
	    	XYPlot plot = chart.getXYPlot();
			ValueAxis domainAxis = plot.getDomainAxis();
			domainAxis.setAutoRange(true);
			domainAxis.setFixedAutoRange(DRAW_LAST_N_VALUE); 
			domainAxis.setAutoTickUnitSelection(false);
			domainAxis.setVerticalTickLabels(true);
			return chart;       
	    }

	    
		public void register(String seriesId, double data) {		//create new curve in chart
			XYSeries xys = new XYSeries(seriesId);
			dataSet.addSeries(xys);
			if(dataSet.getDomainUpperBound(false) != dataSet.getDomainUpperBound(false)) {	//check if(dataSet.getDomainUpperBound(false) == NaN)
				xys.add(0,data);
			}		
			else
				xys.add(dataSet.getDomainUpperBound(false), data);	
			series.add(seriesId);
		}
		
		public void addElement(double relativePhase, double avgPeriod, String seriesId, int status) {
	    	if(currentLine.containsKey(seriesId)) {
	    		synchronized (paint) {
			    	data.add(currentLine);
			    	if(data.size() >= MAXSAMPLES) 
			    		paint.notify();
				}
				currentLine = new HashMap<String, StoreType>();
	    	}
	    	currentLine.put(seriesId, new StoreType(avgPeriod, relativePhase, status));			
		}
	    
	    class PaintThread extends Thread {
	    	
	    	public void run() {
				ArrayList<HashMap<String,StoreType>> dataClone;
	    		while(true) {
	    			synchronized (this) {
						try {
							this.wait();
						} catch (InterruptedException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
						dataClone =  (ArrayList<HashMap<String,StoreType>>) data.clone();
						data = new ArrayList<HashMap<String, StoreType>>();
					}
					
					for(HashMap<String,StoreType> line : dataClone) {
						for(String key : line.keySet()) {
							StoreType value = line.get(key);
					    	XYSeries xys = dataSet.getSeries(series.indexOf(key));
							if(value.status != RelativePhaseCalculator.STATUS_OK) 
					   			xys.add(xys.getMaxX()+1, null);
							else 
								xys.add(xys.getMaxX()+1, value.phase);
						}
					}
	    		}
	    	}
	    }
	}
	
	class PeriodChart extends Chart {
		
		PaintThread paint;

		public PeriodChart(String chartTitle, AppFrame appframe, String xAxis, String yAxis) {
			super(chartTitle, appframe, xAxis, yAxis);
		}
		
		public void initalize() {
	        paint = new PaintThread();
			paint.setName(tit);
	        paint.start();
		}
		
		public void addElement(double relativePhase, double avgPeriod, String seriesId, int status) {
	    	if(currentLine.containsKey(seriesId)) {
	    		synchronized (paint) {
			    	data.add(currentLine);
			    	if(data.size() >= MAXSAMPLES) 
			    		this.paint.notify();
				}
				currentLine = new HashMap<String, StoreType>();
	    	}
	    	currentLine.put(seriesId, new StoreType(avgPeriod, relativePhase, status));			
		}
		
		class PaintThread extends Thread {
	    	
	    	public void run() {
				ArrayList<HashMap<String,StoreType>> dataClone;
	    		while(true) {
	    			synchronized (this) {
						try {
							this.wait();
						} catch (InterruptedException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
						dataClone =  (ArrayList<HashMap<String,StoreType>>) data.clone();
						data = new ArrayList<HashMap<String, StoreType>>();
					}
					
					for(HashMap<String,StoreType> line : dataClone) {
						for(String key : line.keySet()) {
							StoreType value = line.get(key);
					    	XYSeries xys = dataSet.getSeries(series.indexOf(key));
							if(value.status != RelativePhaseCalculator.STATUS_OK) 
					   			xys.add(xys.getMaxX()+1, null);
							else 
								xys.add(xys.getMaxX()+1, value.period);
						}
					}
	    		}
	    	}
	    }
	}
	
	class UnwrapChart extends Chart {
		
		HashMap<String, ArrayList<Double>> avgPhase;
		HashMap<String, Double> lastRelativePhase;	//stored the series last relative phases
		HashMap<String, Integer> overflowCounter; 
		PaintThread paint;
		
		public UnwrapChart(String chartTitle, AppFrame appframe, String xAxis, String yAxis) {
			super(chartTitle,appframe, xAxis, yAxis);
			lastRelativePhase = new HashMap<String, Double>();
			overflowCounter = new HashMap<String, Integer>();
			avgPhase = new HashMap<String, ArrayList<Double>>();
		}
		
		public void initalize() {
	        paint = new PaintThread();
	        paint.setName(tit);
	        paint.start();
		}
		
		public void addElement(double relativePhase, double avgPeriod, String seriesId, int status) {
	    	if(currentLine.containsKey(seriesId)) {
	    		synchronized (paint) {
			    	data.add(currentLine);
			    	if(data.size() >= MAXSAMPLES) 
			    		this.paint.notify();
				}
				currentLine = new HashMap<String, StoreType>();
	    	}
	    	currentLine.put(seriesId, new StoreType(avgPeriod, relativePhase, status));			
		}
		
		public void register(String seriesId, double data) {		//create new curve in chart
			super.register(seriesId, PI);
			lastRelativePhase.put(seriesId, PI);	//add initial value to not jump +-2PI at the start point
			overflowCounter.put(seriesId,0);
			avgPhase.put(seriesId, new ArrayList<Double>());
		}

	    class PaintThread extends Thread {
	    	
	    	public HashMap<String, Double> lastPhaseMap = new HashMap<String, Double>();
	    	public HashMap<String, Double> unwrappedPhaseMap = new HashMap<String, Double>();
	    	
	    	public HashMap<String, Double> unwrap(HashMap<String, StoreType> line) {
	    		HashMap<String, Double> phaseMap = new HashMap<String, Double>();

	    		for (Map.Entry<String, StoreType> entry : line.entrySet()) {
	    			String seriesId = entry.getKey();
	    			StoreType store = entry.getValue();

	    			double speed = 0.0;
	    			
	    			if (store.status == RelativePhaseCalculator.STATUS_OK) {
	    				double phase = store.phase;
	    				assert (0.0 <= phase && phase < Math.PI * 2);
	    			
	    				Double lastPhaseObj = lastPhaseMap.get(seriesId);
	    				double lastPhase = lastPhaseObj == null ? 0.0 : lastPhaseObj.doubleValue();
	    				lastPhaseMap.put(seriesId, phase);
	    			
	    				speed = phase - lastPhase;
	    				if (speed > Math.PI)
	    					speed -= Math.PI;
	    				else if (speed < -Math.PI)
	    					speed += Math.PI;
	    			}

	    			Double unwrappedPhaseObj = unwrappedPhaseMap.get(seriesId);
	    			double unwrappedPhase = unwrappedPhaseObj == null ? 0.0 : unwrappedPhaseObj.doubleValue();
	    			
	    			unwrappedPhase += speed;
	    			unwrappedPhaseMap.put(seriesId, unwrappedPhase);
	    			
	    			phaseMap.put(seriesId, unwrappedPhase);
	    		}
	    		
	    		return phaseMap;
	    	}
	    	
	    	public void run() {
				ArrayList<HashMap<String,StoreType>> dataClone;
				double lastRF;
	    		while(true) {
	    			synchronized (this) {
						try {
							this.wait();
						} catch (InterruptedException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
						dataClone =  data;
						data = new ArrayList<HashMap<String, StoreType>>();
					}
/*	    			
	    			HashMap<String, Double> phaseMap = new HashMap<String,Double>();
	    			for(String key : series) 
	    				phaseMap.put(key, 0.0);
	    			
					for(HashMap<String,StoreType> line : dataClone) {
						for(String key : series) {
							StoreType value = line.get(key);
							if(value.status == RelativePhaseCalculator.STATUS_OK) {
								lastRF = lastRelativePhase.get(key);
								lastRelativePhase.put(key, value.phase);
		    					if( lastRF - value.phase > PI) {
									overflowCounter.put(key, (overflowCounter.get(key)+1));
								} else if( value.phase - lastRF > PI) {
									overflowCounter.put(key, (overflowCounter.get(key)-1));
								} 
								phaseMap.put(key, phaseMap.get(key) + value.phase + (overflowCounter.get(key)*PI2));
							}
						}
					}
					
	    			for(String key : series) {
	    				double avgPhase = phaseMap.get(key)/dataClone.size();
	    				XYSeries xys = dataSet.getSeries(series.indexOf(key));
	    				if(avgPhase == 0)
							xys.add(xys.getMaxX()+1, null);
	    				else {
							xys.add(xys.getMaxX()+1, avgPhase);
						}
	    			}
*/
					for(HashMap<String, StoreType> line : dataClone) {
						HashMap<String, Double> phaseMap = unwrap(line);
						for(String key : series) {
		    				XYSeries xys = dataSet.getSeries(series.indexOf(key));
		    				Double phase = phaseMap.get(key);
		    				if(phase == null)
								xys.add(xys.getMaxX()+1, null);
		    				else
								xys.add(xys.getMaxX()+1, (double) phase);
						}
					}
	    		}
	    	}
	    }
	}

	AppFrame appFrame;
	Chart drwRelativePhase;
	Chart drwPeriod;
	UnwrapChart drwUnwrapPhase;

	public DrawRelativePhase(String appTitle, String chartTitle, int[] otherNode) {	//chartTitle is the reference node id
		appFrame = new AppFrame(appTitle);
		drwRelativePhase = new Chart("Relative Phase",appFrame, "Sample", "Radian");
		drwRelativePhase.initalize();
		drwPeriod = new PeriodChart("Period",appFrame,"Sample", "Sample");
		drwPeriod.initalize();
		drwUnwrapPhase = new UnwrapChart("Unwrap Phase",appFrame, "Sample", "Radian");
		drwUnwrapPhase.initalize();
		drwRelativePhase.chart.getXYPlot().getRangeAxis().setRange(0.00,2*Math.PI);
		appFrame.pack( );          
		RefineryUtilities.centerFrameOnScreen(appFrame);          
		appFrame.setVisible(true);
		addSeriesToChart(otherNode);
	}
	
	private void addSeriesToChart(int[] otherNode) {
		for(int i : otherNode) {
			drwRelativePhase.register(i+"", 0.0);
			drwPeriod.register(i+"", 0.0);
			drwUnwrapPhase.register(i+"", 0.0); 	
		}
	}

	public void relativePhaseReceived(final double relativePhase, final double avgPeriod, final int status, int slotId, int rx1, int rx2) {
		final String str = rx2+"";
		newDataComing(relativePhase, avgPeriod, status, str);
	}
	
	public void newDataComing(final double relativePhase, final double avgPeriod, int status, final String seriesId) {
		drwPeriod.addElement(relativePhase, avgPeriod, seriesId, status);
		drwRelativePhase.addElement(relativePhase, avgPeriod, seriesId, status);
		drwUnwrapPhase.addElement(relativePhase, avgPeriod, seriesId, status);
	}
	
}
