import java.util.HashMap;


public class PhaseDistributionMeasure implements RelativePhaseListener{
	
	HashMap<Integer, Integer> distribution = new HashMap<Integer,Integer>();
	int counter = 0;

	public void relativePhaseReceived(final double relativePhase, final double avgPeriod, final int status, int slotId, int rx1, int rx2) {
		if(status == RelativePhaseCalculator.STATUS_OK){
			
			counter++;
			
			int phaseInDegree = (int)( ( relativePhase / (2*Math.PI)) * 360 );
			if(distribution.containsKey(phaseInDegree)){
				int currentValue = distribution.get(phaseInDegree);
				distribution.put(phaseInDegree, currentValue+1);
			}else{
				distribution.put(phaseInDegree, 1);
			}
		}
		
		if(counter % 100 == 0){
			System.out.println(counter+":  "+relativePhase);
		}
		
		if(counter == 70000){
			System.out.println("Distribution:");
			for(int i=0 ; i<361; i++){
				if(distribution.containsKey(i)){
					System.out.println(i+";"+distribution.get(i));
				}
			}
			System.exit(0);
		}
	}
	
	
}
