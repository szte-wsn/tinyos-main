import java.util.HashMap;
import java.util.Map;


public class ErrorsWriteToConsole  implements SlotListener{
	
	public static final int WAITFORWRITETOCONSOLE = 1000;
	private static final int RECEIVEDMEASID = 0;
	
	Map<Integer, Integer> errors;
	
	public ErrorsWriteToConsole() {
		errors = new HashMap<Integer,Integer>();
		errors.put(RECEIVEDMEASID, 0);
		errors.put(SlotMeasurement.ERR_CALCULATION_TIMEOUT, 0);
		errors.put(SlotMeasurement.ERR_FEW_ZERO_CROSSINGS, 0);
		errors.put(SlotMeasurement.ERR_LARGE_PERIOD, 0);
		errors.put(SlotMeasurement.ERR_NO_MEASUREMENT, 0);
		errors.put(SlotMeasurement.ERR_PERIOD_MISMATCH, 0);
		errors.put(SlotMeasurement.ERR_SMALL_MINMAX_RANGE, 0);
		errors.put(SlotMeasurement.ERR_START_NOT_FOUND, 0);
		errors.put(SlotMeasurement.ERR_ZERO_PERIOD, 0);
		(new ErrorWriteToConsoleThread()).start();
	}
	
	public class ErrorWriteToConsoleThread extends Thread {
	    public void run() {
	    	System.out.println(String.format("%10s %5s %5s %5s %5s %5s %5s %5s %5s",
	    			"Received",
	    			"Start",
	    			"Apml",
	    			"FewZ",
	    			"LPer",
	    			"PerM",
	    			"ZPer",
	    			"TimeO",
	    			"NoMea"));
	        for(;;) {
	        	String line;
	        	synchronized (errors) {
		        	line = String.format("%10d %5d %5d %5d %5d %5d %5d %5d %5d",
		        			errors.get(RECEIVEDMEASID),
		        			errors.get(SlotMeasurement.ERR_START_NOT_FOUND),
		        			errors.get(SlotMeasurement.ERR_SMALL_MINMAX_RANGE),
		        			errors.get(SlotMeasurement.ERR_FEW_ZERO_CROSSINGS),
		        			errors.get(SlotMeasurement.ERR_LARGE_PERIOD),
		        			errors.get(SlotMeasurement.ERR_PERIOD_MISMATCH),
		        			errors.get(SlotMeasurement.ERR_ZERO_PERIOD),
		        			errors.get(SlotMeasurement.ERR_CALCULATION_TIMEOUT),
		        			errors.get(SlotMeasurement.ERR_NO_MEASUREMENT));
	        	}
	        	System.out.println(line);
        		try {
	        		Thread.sleep(WAITFORWRITETOCONSOLE);
	        	} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
	        }      
	    }
	}

	@Override
	public void slotReceived(Slot receivedSlot, int sfcounter) {
		for(SlotMeasurement meas: receivedSlot.measurements){
			int err = meas.getErrorCode();
			if( err!= SlotMeasurement.NO_ERROR ){
				errors.put(err, errors.get(err)+1);
			}
		}
		errors.put(RECEIVEDMEASID, errors.get(RECEIVEDMEASID) + receivedSlot.measurements.size());
		
	}

	
}
