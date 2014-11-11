import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;


public class ErrorsWriteToConsole  implements RelativePhaseListener{
	
	public static final int WAITFORWRITETOCONSOLE = 1000;
	
	Map<Integer, Integer> errors;
	
	public ErrorsWriteToConsole() {
		errors = new HashMap<Integer,Integer>();
		(new ErrorWriteToConsoleThread()).start();
	}
	
	public class ErrorWriteToConsoleThread extends Thread {
	    public void run() {
	        for(;;) {	
	        	System.out.println("");
	        	for(Entry<Integer, Integer> entry : errors.entrySet()) {
        		    int status = entry.getKey();
        		    int value = (Integer)entry.getValue();
        			if(status == RelativePhaseCalculator.STATUS_PERIOD_NOT_CALCULATED)
        				System.out.println("STATUS_PERIOD_NOT_CALCULATED: " + value);
        			else if(status == RelativePhaseCalculator.ERR_START_NOT_FOUND) 
        	    		System.out.println("ERR_START_NOT_FOUND: " + value);
        			else if(status == RelativePhaseCalculator.ERR_SMALL_MINMAX_RANGE)
        	    		System.out.println("ERR_SMALL_MINMAX_RANGE: " + value);
        			else if(status == RelativePhaseCalculator.ERR_FEW_ZERO_CROSSINGS)
        	    		System.out.println("ERR_FEW_ZERO_CROSSINGS: " + value);
        			else if(status == RelativePhaseCalculator.ERR_LARGE_PERIOD)
        				System.out.println("ERR_LARGE_PERIOD: " + value);
        			else if(status == RelativePhaseCalculator.ERR_PERIOD_MISMATCH)
        				System.out.println("ERR_PERIOD_MISMATCH: " + value);
        			else if(status == RelativePhaseCalculator.ERR_ZERO_PERIOD)
        				System.out.println("ERR_ZERO_PERIOD: " + value);
        		}
	        	System.out.println("");
        		try {
	        		Thread.sleep(WAITFORWRITETOCONSOLE);
	        	} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
	        }      
	    }
	}
	
	public void addError(int status) {
		if(!errors.containsKey(status))
			errors.put(status, 1);
		else
			errors.put(status, errors.get(status)+1);
	}

	@Override
	public void relativePhaseReceived(double relativePhase, double avg_period,
			int status, int slotId, int rx1, int rx2) {
		addError(status);
	}
	
}
