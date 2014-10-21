import java.awt.BasicStroke;
import java.awt.Color;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.XYPlot;
import org.jfree.chart.renderer.xy.XYLineAndShapeRenderer;
import org.jfree.data.xy.XYDataset;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;
import org.jfree.ui.ApplicationFrame;
import org.jfree.ui.RefineryUtilities;




public class WaveformPlotter implements plotWaveform{

	/**
	 * To store the waveform which will be plotted.
	 */
	private Short[] data;
	/**
	 * The thread that plots the waveform.
	 */
	private plotData plotterThread;

	public WaveformPlotter(String name){
		data = new Short[Consts.BUFFER_LEN_MIG];
		plotterThread = new plotData(this,name);
		plotterThread.setPriority(Thread.MIN_PRIORITY);
		plotterThread.start();
	}


	/* 
	 * @see plotWaveform#plot(java.lang.Short[])
	 */
	public void plot(Short[] waveform){
		System.arraycopy(waveform, 0, data, 0,waveform.length );
		plotterThread.refreshChart(data);
	}


}

class plotData extends Thread{
	WaveformPlotter wfplotter;
	WaveformChart wfchart;

	public plotData(WaveformPlotter mWfpr,String name){
		wfchart = new WaveformChart("Waveform Plotter",name);
		this.wfplotter = mWfpr;
	}

	/* 
	 * @see java.lang.Thread#run()
	 * Creates the surface for waveform plotting.
	 */
	public void run(){
		wfchart.pack( );          
		RefineryUtilities.centerFrameOnScreen( wfchart );          
		wfchart.setVisible( true ); 
	}

	/**
	 * @param data : that will be plotted
	 * Refreshes the surface with the new waveform.
	 */
	public  void refreshChart(Short[] data){
		wfchart.refreshWaveform(data);
	}

}

class WaveformChart  extends ApplicationFrame  {


	private static final long serialVersionUID = 1L;
	ChartPanel chartPanel;

	public WaveformChart(String appTitle,String chartTitle) {
		super(appTitle);
		XYDataset dataset = createDataset(new Short[Consts.BUFFER_LEN_MIG] );         
		JFreeChart xylineChart = ChartFactory.createXYLineChart(
				chartTitle ,
				"Sample" ,
				"RSSI" ,
				dataset ,
				PlotOrientation.VERTICAL ,
				true , true , false);   
		chartPanel = new ChartPanel( xylineChart );   
		chartPanel.setPreferredSize( new java.awt.Dimension( 560 , 370 ) );         
		chartPanel.setMouseZoomable( true , false );     
		final XYPlot plot = xylineChart.getXYPlot( );
		XYLineAndShapeRenderer renderer = new XYLineAndShapeRenderer( );
		renderer.setSeriesPaint( 0 , Color.RED );
		renderer.setSeriesStroke( 0 , new BasicStroke( 3.0f ) );
		plot.setRenderer( renderer ); 
		setContentPane( chartPanel );
	}

	private XYDataset createDataset( Short[] data) 
	{
		XYSeries waveform = new XYSeries( "Waveform" );         
		for (int i = 0; i < Consts.BUFFER_LEN_MIG; i++)    
		{
			try 
			{
				waveform.add(i, data[i] );                 
			}
			catch ( Exception e ) 
			{
				System.err.println("Error adding to series");
			}
		}
		return new XYSeriesCollection(waveform);
	} 

	public void refreshWaveform( Short[] data){
		XYDataset dataset = createDataset(data ); 
		chartPanel.getChart().getXYPlot().setDataset(dataset);
	}


} 