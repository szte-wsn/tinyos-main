import java.awt.GridLayout;
import java.util.ArrayList;
import java.util.HashMap;

import javax.swing.JPanel;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.ValueAxis;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.XYPlot;
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
						dataClone = data;
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
						dataClone = data;
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
		protected HashMap<String, PhaseUnwrapper> unwrappers = new HashMap<String, PhaseUnwrapper>();
		protected HashMap<String, Double> dataLine = new HashMap<String, Double>();
		protected ArrayList<HashMap<String, Double>> dataLines = new ArrayList<HashMap<String, Double>>();
		PaintThread paint;
		
		public UnwrapChart(String chartTitle, AppFrame appframe, String xAxis, String yAxis) {
			super(chartTitle, appframe, xAxis, yAxis);
		}
		
		public void initalize() {
	        paint = new PaintThread();
	        paint.setName(tit);
	        paint.start();
		}
		
		public void addElement(double relativePhase, double avgPeriod, String seriesId, int status) {
	    	if(dataLine.containsKey(seriesId)) {
	    		synchronized (paint) {
			    	dataLines.add(dataLine);
			    	if(dataLines.size() >= MAXSAMPLES) 
			    		paint.notify();
				}
				dataLine = new HashMap<String, Double>();
	    	}
	    	
	    	PhaseUnwrapper unwrapper = unwrappers.get(seriesId);
	    	double unwrappedPhase = unwrapper.unwrap(relativePhase);
	    	dataLine.put(seriesId, unwrappedPhase);
		}
		
		public void register(String seriesId, double data) {
			super.register(seriesId, PI);
			unwrappers.put(seriesId, new PhaseUnwrapper(seriesId));
		}

	    class PaintThread extends Thread {
	    	public void run() {
				ArrayList<HashMap<String, Double>> lines;
	    		while(true) {
	    			synchronized (this) {
						try {
							this.wait();
						} catch (InterruptedException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
						lines =  dataLines;
						dataLines = new ArrayList<HashMap<String, Double>>();
					}

	    			for(HashMap<String, Double> line : lines) {
						for(int index = 0; index < series.size(); index++) {
							String key = series.get(index);
		    				Double data = line.get(key);
		    				XYSeries xys = dataSet.getSeries(index);
		    				if(data == null)
								xys.add(xys.getMaxX()+1, null);
		    				else
								xys.add(xys.getMaxX()+1, data.doubleValue());
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
