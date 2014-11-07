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
	 * @author Gyoorey
	 * This class represents a chart for a waveform
	 */
	class WaveformChart extends JPanel{
		
		private static final long serialVersionUID = 1L;
	    
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
					false , true , false);   
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


	HashMap<Short , WaveformChart> waveforms = new HashMap<Short , WaveformChart>();	
	JFrame frame;

	
	/**
	 * @param name Defines the title of the chart.
	 * Constructor.
	 */
	public WaveformPlotter(String name){
		frame = new JFrame(name);
        frame.setSize(600, 400);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setLayout(new GridLayout(0, 2));
        frame.setVisible(true);
	}
	
	/**
	 * Refreshes the data of an already added plot
	 * @param id The id of the plot
	 * @param waveform The data itself
	 */
	public void plot(Short[] waveform, short id){
		if(waveforms.containsKey(id)){
			waveforms.get(id).refreshWaveform(waveform);
		}
	}

	/**
	 * @param nodeId Defines the nodeId for the new waveform.
	 * Adds a new waveform to the JFrame.
	 */
	public void addWaveform(short nodeId){
		if(!waveforms.containsKey(nodeId)){
			waveforms.put(nodeId, new WaveformChart(nodeId+"."));
			frame.add(waveforms.get(nodeId));
			frame.pack();
			frame.setVisible(true);
		}
	}

}