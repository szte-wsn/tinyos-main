module MeasureWaveC{
	provides interface MeasureWave;
	
	uses interface DiagMsg;
}
implementation{
	enum{
		START = 0,
		ENDSFOUND = 1, 
		AVERAGEFOUND = 2, //also the amplitudes
		PERIODFOUND = 3,
		PHASEFOUND = 4,
		NODATA = 17,
		NOPERIOD = 18,
		NOPHASE = 19,
	};
	
	typedef struct measurement_t{
		uint8_t *data;
		uint16_t len;
		uint16_t phaseRef;
		uint16_t start;
		uint16_t safelen;
		uint8_t threshold;
		uint8_t average;
		uint16_t period:14;
		uint16_t periodfraction:2;
		uint8_t phase;
		uint8_t minAmplitude:5;
		uint8_t maxAmplitude:5;
		uint8_t state:6;
	} measurement_t;
	
	measurement_t measurement;
	
	void getEnds(){
		measurement.phaseRef = 0;
		while( *(measurement.data + measurement.phaseRef) < measurement.threshold && measurement.phaseRef < measurement.len ){
			measurement.phaseRef++;
		}
		measurement.safelen = measurement.len;
		while( *(measurement.data + measurement.safelen) < measurement.threshold && measurement.safelen > 0 ){
			measurement.safelen--;
		}
		if( measurement.safelen < (measurement.phaseRef + 2*measurement.start) ){ //start currently holds the safety lead in/out time
			measurement.safelen = 0;
			//no usable data
			measurement.average = 0;
			measurement.phase = 0;
			measurement.period = 0;
			measurement.minAmplitude = 0;
			measurement.maxAmplitude = 0;
			measurement.state = NODATA;
		} else {
			measurement.safelen -= measurement.phaseRef + 2*measurement.start;
			measurement.start+=measurement.phaseRef;
			measurement.state = ENDSFOUND;
		}
	}
	
	void getAverage(){
		uint32_t temp = 0;
		uint16_t i;
		measurement.minAmplitude = *(measurement.data+measurement.start);
		measurement.maxAmplitude = *(measurement.data+measurement.start);
		for(i=measurement.start;i<measurement.safelen;i++){
			temp += *(measurement.data+i);
			if( measurement.minAmplitude > *(measurement.data+i) )
				measurement.minAmplitude = *(measurement.data+i);
			if( measurement.maxAmplitude < *(measurement.data+i) )
				measurement.maxAmplitude = *(measurement.data+i);
		}
		measurement.average = temp/measurement.safelen;
		measurement.state = AVERAGEFOUND;
	}
	
	void getPeriod(){
		uint32_t temp;
		uint16_t crossingCount = 0;
		uint16_t lastCrossing = 0;
		uint16_t i = measurement.start;
		
		//we only search for RISING crossings (so we measure full periods, not half periods)
		while(  i<measurement.safelen && *(measurement.data+i) >= (measurement.average - 1) )
			i++;
		while( i<measurement.safelen ){
			//search the next crossing
			while( i<measurement.safelen && *(measurement.data+i) < measurement.average )
				i++;
			
			if( i<measurement.safelen ){ //new crossing point
				if( crossingCount!=0 ){
					temp += (i-lastCrossing);
				}
				crossingCount++;
				lastCrossing = i;
				while(  i<measurement.safelen && *(measurement.data+i) >= (measurement.average - 1) ) //go through the upper half period, and a bit more, to avoid oscillation near the average
					i++;
			}
		}
		if( crossingCount > 1 ){
			measurement.period = temp/(crossingCount-1);
			measurement.periodfraction = ((temp*100)/(crossingCount-1))%100;
			measurement.state = PERIODFOUND;
		} else {
			measurement.phase = 0;
			measurement.period = 0;
			measurement.state = NOPERIOD;
		}
	}
	
	//all the windows
	#define PHASE_WINDOWS 4
	//how many window overlaps each other at any given phase (five year old explanation: if you draw the windows, how many line do you need)
	#define PHASE_WINDOW_OVERLAP 2
	inline static uint8_t getPhaseWindowLimit(uint8_t number){
		return number*measurement.period/PHASE_WINDOWS;
	}
	
	void getPhase(){
		uint16_t i = measurement.start;
		uint16_t end = (((uint32_t)measurement.period*measurement.period)>>2)+measurement.start;
		int32_t temp[PHASE_WINDOWS] = {0,0,0,0};
		uint16_t count[PHASE_WINDOWS] = {0,0,0,0};
		
		if( end<measurement.safelen ){ //move the window to the middle of the sample
			uint16_t offset2 = (measurement.safelen - end) >> 1;
			end+=offset2;
			i+=offset2;
		} else {
			end = measurement.safelen;
		}
		
		while(  i<end && *(measurement.data+i) >= (measurement.average - 1) )
			i++;
		
		while(i<end){
			while( i<end && *(measurement.data+i) < measurement.average )
				i++;
			
			if( i<end ){ //new crossing point
				uint8_t j;
				uint16_t phase = i - measurement.phaseRef;
				phase = phase % measurement.period;
				
				//we have (PHASE_WINDOW_OVERLAP - 1) special windows. Always the last ones
				for(j=0;j<PHASE_WINDOWS-(PHASE_WINDOW_OVERLAP - 1);j++){
					if( phase > getPhaseWindowLimit(j) && phase <= getPhaseWindowLimit(j+PHASE_WINDOW_OVERLAP)){
						temp[j]+=phase;
						count[j]++;
					}
				}
				//the last window(s) is (are) overlapping around zero phase, so it's a bit more difficult: very large phases are counted as negative (phase-period)
				j=1;
				while(j<=PHASE_WINDOW_OVERLAP){
					if( phase <= getPhaseWindowLimit(j) ){ //very small phase
						temp[j]+=phase;
						count[j]++;
					}
					if( phase > getPhaseWindowLimit(PHASE_WINDOWS-PHASE_WINDOW_OVERLAP+j)){ //very large phase
						temp[j]+=(phase-measurement.period);
						count[j]++;
					}
				}
				
				while(  i<end && *(measurement.data+i) >= (measurement.average - 1) ) //go through the upper half period, and a bit more, to avoid oscillation near the average
					i++;
			}
		}
		
		end = 0; //reuse variable for maximum search
		for(i=1;i<PHASE_WINDOWS;i++){
			if( count[i] > count[end] ){
				end = i;
			}
		}
		if( count[end] > 0 ) {
			temp[end] = temp[end]/count[end];
			if( temp[end] < 0 ){ //possible with zero overlapping phases
				temp[end]+=measurement.period;
			}
			measurement.phase = (temp[end] << 8)/measurement.period;
			measurement.state = PHASEFOUND;
		} else {
			measurement.phase = 0;
			measurement.state = NOPHASE;
		}
	}
	
	void calculate(uint8_t targetState){
		while( measurement.state < targetState ){
			switch(measurement.state){
				case START:{
					getEnds();
				}break;
				case ENDSFOUND:{
					getAverage();
				}break;
				case AVERAGEFOUND:{
					getPeriod();
				}break;
				case PERIODFOUND:{
					getPhase();
				}break;
			}
		}
	}
	
	command void MeasureWave.changeData(uint8_t *data, uint16_t len, uint8_t threshold, uint8_t leadTime){
		measurement.data = data;
		measurement.len = len;
		measurement.threshold = threshold;
		measurement.start = leadTime;
		measurement.state = START;
	}
	
	command uint8_t MeasureWave.getMinAmplitude(){
		calculate(AVERAGEFOUND);
		return measurement.minAmplitude;
	}
	
	command uint8_t MeasureWave.getMaxAmplitude(){
		calculate(AVERAGEFOUND);
		return measurement.maxAmplitude;
	}
	
	command uint16_t MeasureWave.getPeriod(){
		calculate(PERIODFOUND);
		return measurement.period*100 + measurement.periodfraction;
	}
	
	command uint8_t MeasureWave.getPhase(){
		calculate(PHASEFOUND);
		return measurement.phase;
	}
}
