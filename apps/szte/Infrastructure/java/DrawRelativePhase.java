import java.awt.GridLayout;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;

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

class FileRecord {
	
	String path;
	
	public FileRecord(String path){
		this.path = path;
		File dir = new File(path);
		dir.mkdirs();
	}
	
	public void writeToFile(double relativePhase, double avgPeriod, int status, String fileName) {
		try {
			BufferedWriter out = new BufferedWriter(new FileWriter(path + fileName + ".txt", true));	
			out.write(String.format("Relative phase: %10.7f Avarage period: %10.5f Status: %2d Time: %5tc\n", relativePhase, avgPeriod, status, new Date()));
			out.close();
		} catch(IOException e) {
			e.printStackTrace();
		}
	}
}

class Chart {
	
	static final int DRAW_LAST_N_VALUE = 80;
	static final double PI = Math.PI;
	static final double PI2 = 2*Math.PI;
	
	XYSeriesCollection dataSet; 
	ArrayList<String> series;	//store the curves dataset index. String = "slotId:rx1,rx2"

	public Chart(String chartTitle, AppFrame appframe) {
		series = new ArrayList<String>();
		dataSet = new XYSeriesCollection();
        JFreeChart chart = createChart(chartTitle);
        ChartPanel chartPanel = new ChartPanel(chart); 
        chartPanel.setPreferredSize(new java.awt.Dimension(500, 270));
        appframe.addChartPanel(chartPanel);
	}
	
    private JFreeChart createChart(String chartTitle) {
    	JFreeChart chart = ChartFactory.createXYLineChart(
			chartTitle,
			"Sample",
			"Radian",
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
    
	public void Register(String seriesId, double relativePhase) {		//create new curve in chart
		XYSeries xys = new XYSeries(seriesId);
		dataSet.addSeries(xys);
		if(dataSet.getDomainUpperBound(false) != dataSet.getDomainUpperBound(false)) {	//check if(dataSet.getDomainUpperBound(false) == NaN)
			xys.add(0,relativePhase);
		}		
		else
			xys.add(dataSet.getDomainUpperBound(false)-1, relativePhase);
		series.add(seriesId);
	}
	
    public void refreshChart(double relativePhase, String seriesId) {
    	XYSeries xys = dataSet.getSeries(series.indexOf(seriesId));
    	xys.add(xys.getMaxX()+1, relativePhase);
    }
}

class UnwrapChart extends Chart {
	
	public UnwrapChart(String chartTitle, AppFrame appframe) {
		super(chartTitle,appframe);
	}
	
	public void refreshChart(double relativePhase, String seriesId) {
		XYSeries xys = dataSet.getSeries(series.indexOf(seriesId));
		double prev = xys.getDataItem(xys.getItemCount()-1).getYValue();
		if( prev - relativePhase > PI)
			relativePhase += PI2;
		if( relativePhase - prev > PI) 
			relativePhase -= PI2;
		xys.add(xys.getMaxX()+1, relativePhase);		
	}
	
}

class DrawThread extends Thread {
	
	AppFrame appFrame;
	Chart drwRelativePhase;
	Chart drwPeriod;
	UnwrapChart drwUnwrapPhase;
	FileRecord fr;
	ArrayList<String> slots;	//String = "slotid,rx1,rx2"
	
	public DrawThread(String appTitle, String chartTitle) {
		appFrame = new AppFrame(appTitle);
		drwRelativePhase = new Chart("Relative Phase",appFrame);
		drwPeriod = new Chart("Period",appFrame);
		drwUnwrapPhase = new UnwrapChart("Unwrap Phase",appFrame);
		fr = new FileRecord("relativePhases/");
		slots = new ArrayList<String>();
	}
	
	public void run(){
		appFrame.pack( );          
		RefineryUtilities.centerFrameOnScreen(appFrame);          
		appFrame.setVisible(true);
	}
	
	public void newDataComing(double relativePhase, double avgPeriod, int status, String seriesId) {
		if(!slots.contains(seriesId)) {	//if not exists in the chart
			slots.add(seriesId);
			drwRelativePhase.Register(seriesId, relativePhase);
			drwPeriod.Register(seriesId, relativePhase);
			drwUnwrapPhase.Register(seriesId, relativePhase);
		} else {
			drwRelativePhase.refreshChart(relativePhase, seriesId);
			drwPeriod.refreshChart(avgPeriod, seriesId);
			drwUnwrapPhase.refreshChart(relativePhase, seriesId);
		}
		fr.writeToFile(relativePhase, avgPeriod, status, seriesId);
	}
}

public class DrawRelativePhase implements RelativePhaseListener{
	
	DrawThread drw;

	public DrawRelativePhase(String appTitle, String chartTitle) {	//chartTitle is the reference node id
		drw = new DrawThread(appTitle, chartTitle); 
		drw.start();
	}

	public void relativePhaseReceived(double relativePhase, double avgPeriod, int status, int slotId, int rx1, int rx2) {
		System.out.println("RelPhase: " + relativePhase + " avgPeriod: " + avgPeriod + " " + " status: " + status + " slotId: " + slotId);
		String str = slotId + ":" + rx1 + "," + rx2;
		drw.newDataComing(relativePhase, avgPeriod, status, str);
	}
}
