import java.awt.Color;
import java.awt.GridLayout;
import java.util.HashMap;

import javax.swing.JFrame;
import javax.swing.JPanel;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.data.xy.XYDataset;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;




/**
 * @author Gyoorey
 * The main class which can plot multiple waveforms.
 */
public class WaveformPlotter implements plotWaveform{

	/**
	 * To store the waveform which will be plotted.
	 */
	private Short[] data;
	/**
	 * The thread that plots the waveform.
	 */
	private plotDataThread plotterThread;

	
	/**
	 * @param name Defines the title of the chart.
	 * Constructor.
	 */
	public WaveformPlotter(String name){
		data = new Short[Consts.BUFFER_LEN_MIG];
		plotterThread = new plotDataThread(this,name);
		plotterThread.setPriority(Thread.MIN_PRIORITY);
		plotterThread.start();
	}
	/* 
	 * @see plotWaveform#plot(java.lang.Short[])
	 */
	public void plot(Short[] waveform, short nodeId){
		System.arraycopy(waveform, 0, data, 0,waveform.length );
		plotterThread.refreshChart(data,nodeId);
	}

	/**
	 * @param nodeId Defines the nodeId for the new waveform.
	 * Adds a new waveform to the JFrame.
	 */
	public void addWaveform(short nodeId){
		plotterThread.addWaveform(nodeId);
	}

}

/**
 * @author Gyoorey
 *	The thread which handles the waveform plottings.
 */
class plotDataThread extends Thread{
	WaveformPlotter wfplotter;
	
	JFrame frame;
	HashMap<Short , WaveformChart> waveforms;

	/**
	 * @param mWfpr The class which runs this thread.
	 * @param name  The name of the frame.
	 */
	public plotDataThread(WaveformPlotter mWfpr,String name){
		this.wfplotter = mWfpr;
		waveforms = new HashMap<Short , WaveformChart>();
	}

	/* 
	 * @see java.lang.Thread#run()
	 * Creates the surface for waveform plotting.
	 */
	public void run(){
		frame = new JFrame("Waveforms");
        frame.setSize(600, 400);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setLayout(new GridLayout(0, 2));
        frame.setVisible(true);
        return;
	}
	
	/**
	 * @param nodeId Which nodeId's waveform is this.
	 * Adds a new waveform with a specified nodeId.
	 */
	public void addWaveform(short nodeId){
		if(!waveforms.containsKey(nodeId)){
			waveforms.put(nodeId, new WaveformChart(nodeId+"."));
			frame.add(waveforms.get(nodeId));
			frame.pack();
	        frame.setVisible(true);
		}
	}

	/**
	 * @param data : that will be plotted
	 * Refreshes the surface with the new waveform.
	 */
	public  void refreshChart(Short[] data, short nodeId){
		if(waveforms.containsKey(nodeId)){
			waveforms.get(nodeId).refreshWaveform(data);
		}
	}

}

/**
 * @author Gyoorey
 * This class represents a chart for a waveform
 */
class WaveformChart extends JPanel{
	
	private static final long serialVersionUID = 1L;
	private static final int W = 200;
    private static final int H = 70;
    
    /**
     * A chart which contains a waveform.
     */
    private ChartPanel chartPanel;
	
	/**
	 * @param chartTitle The title of the chart. 
	 * Constructor. Crates a new waveform with empty DataSet();
	 */
	public WaveformChart(String chartTitle){
		this.setLayout(new GridLayout());
		XYDataset dataset = createDataset(new Short[Consts.BUFFER_LEN_MIG] );         
		JFreeChart xylineChart = ChartFactory.createXYLineChart(
				chartTitle ,
				"Sample" ,
				"RSSI" ,
				dataset ,
				PlotOrientation.VERTICAL ,
				true , true , false);   
		chartPanel = new ChartPanel( xylineChart );   
        this.add(chartPanel);
	}
	
	/**
	 * @param data Array which cointains the waveform.
	 * @return The new dataset which is calculated from the data paramter.
	 */
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

	/**
	 * @param data The new waveform array.
	 * Refreshes the current waveform with the new data array.
	 */
	public void refreshWaveform( Short[] data){
		XYDataset dataset = createDataset(data ); 
		chartPanel.getChart().getXYPlot().setDataset(dataset);
	}
	
}