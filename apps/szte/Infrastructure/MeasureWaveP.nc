module MeasureWaveP{
	provides interface MeasureWave;
	uses interface Filter<uint8_t>;
	
	uses interface DiagMsg;
}
implementation{
	//consts to configure the calculation algorithm
	enum{
		DROPFIRST=10,//the first DROPFIRST measure will be dropped before phaseref search
		DROPSECOND=40,//the filter/period/phase algorithm will search with phaseRef+DROPSECOND startpoint
		DROPEND=10,//the filter/period/phase algorithm will search with phaseRef+DROPSECOND startpoint
		THRESHOLD=2,//phaseref will be the first point after DROPFIRST, where the measurement is above THRESHOLD
		FILTERWINDOW=7,//lenth of the filter window
		MINPOINTS=8,//how many minimum point will be searched for period calculation (it might found less)
		MINTRESH_RATIO=3,
	};
	
	enum{
		START = 0,
		REFFOUND = 1, 
		FILTERED = 2,
		MINMAXFOUND = 3,
		PERIODFOUND = 4,
		PHASEFOUND = 5,
		NODATA = 17,
		NOMINMAX = 18,
		NOPERIOD = 19,
		NOPHASE = 20,
	};
	
	//input data
	uint8_t *data;
	uint16_t len;
	
	//output data
	uint16_t phaseRef;
	uint16_t period;
	uint8_t phase;
	uint8_t minAmplitude;
	uint8_t maxAmplitude;
	
	//helper variables
	uint16_t firstMin;
	uint16_t calcStart;
	uint16_t calcEnd;
	uint8_t state;

	
	
	void debugPrint(){
		#ifdef DEBUG_MEASUREWAVE
		if (call DiagMsg.record()){
			call DiagMsg.uint16(len);
			
			call DiagMsg.uint8(state);
			call DiagMsg.uint16(calcStart);
			call DiagMsg.uint16(calcEnd);
			call DiagMsg.uint16(firstMin);
			
			call DiagMsg.uint16(phaseRef);
			call DiagMsg.uint8(minAmplitude);
			call DiagMsg.uint8(maxAmplitude);
			call DiagMsg.uint16(period);
			call DiagMsg.uint8(phase);
			call DiagMsg.send();
		}
		#endif
	}
	
	void debugData(){
		#ifdef DEBUG_MEASUREWAVE
		uint16_t offset=0;
		while(offset<len){
			if (call DiagMsg.record()){
				call DiagMsg.hex16(offset);
				call DiagMsg.chr('|');
				call DiagMsg.hex8s((&data[offset]),8);
				call DiagMsg.hex8s((&data[offset+8]),8);
				call DiagMsg.send();
			}
			offset+=16;
		}
		#endif
	}
	
	void getPhaseRef(){
		phaseRef = DROPFIRST;
		calcEnd = len-DROPEND;
		while( data[phaseRef] < THRESHOLD && phaseRef < calcEnd ){
			phaseRef++;
		}
		calcStart = phaseRef+DROPSECOND;
		if(calcStart < calcEnd)
			state = REFFOUND;
		else
			state = NODATA;
	}
	
	void filter(){
		debugData();
		call Filter.filter( &(data[calcStart]), &(data[calcStart]), calcEnd-calcStart, FILTERWINDOW);
		debugData();
		state = FILTERED;
	}
	
	void getMinMax(){
		uint16_t i;
		minAmplitude = 255;
		maxAmplitude = 0;
		for(i=calcStart;i<calcEnd;i++){
			if( data[i] < minAmplitude )
				minAmplitude = data[i];
			if( data[i] > maxAmplitude )
				maxAmplitude = data[i];
		}
		if(minAmplitude < maxAmplitude)
			state = MINMAXFOUND;
		else
			state = NOMINMAX;
	}
	
	void getPeriod(){
		uint8_t minTreshold=minAmplitude+(maxAmplitude-minAmplitude)/MINTRESH_RATIO;
		uint16_t i=calcStart;
		uint8_t minsFound = 0;
		uint16_t lastMin=0;
		uint16_t minStart=0;
		bool searchRising = FALSE;
		while( i<calcEnd && minsFound<MINPOINTS ){
			if( !searchRising && data[i]<minTreshold ){
				searchRising = TRUE;
				minStart=i;
			} else if( searchRising && data[i]>minTreshold ){
				searchRising = FALSE;
				if( ++minsFound == 1 ){
					firstMin = (minStart+i)>>1;
				} else {
					lastMin = (minStart+i)>>1;
				}
			}
			i++;
		}
		if( minsFound > 1 ){
			period=(lastMin-firstMin)/(minsFound-1);
			state=PERIODFOUND;
		}else{
			state = NOPERIOD;
		}
	}
	
	void getPhase(){
		phase=firstMin-phaseRef;
		while(phase>period)
			phase-=period;
		state = PHASEFOUND;
	}
	
	void calculate(uint8_t targetState){
		while( state < targetState ){
			switch(state){
				case START:{
					getPhaseRef();
				}break;
				case REFFOUND:{
					filter();
				}break;
				case FILTERED:{
					getMinMax();
				}
				case MINMAXFOUND:{
					getPeriod();
				}break;
				case PERIODFOUND:{
					getPhase();
				}break;
			}
			debugPrint();
		}
	}
	
	command void MeasureWave.changeData(uint8_t *newData, uint16_t newLen){
		data = newData;
		len = newLen;
		state = START;
	}
	
	command uint8_t MeasureWave.getPhaseRef(){
		calculate(REFFOUND);
		return phaseRef;
	}
	
	command void MeasureWave.filter(){
		calculate(FILTERED);
	}
	
	command uint8_t MeasureWave.getMinAmplitude(){
		calculate(MINMAXFOUND);
		return minAmplitude;
	}
	
	command uint8_t MeasureWave.getMaxAmplitude(){
		calculate(MINMAXFOUND);
		return maxAmplitude;
	}
	
	command uint16_t MeasureWave.getPeriod(){
		calculate(PERIODFOUND);
		return period;
	}
	
	command uint8_t MeasureWave.getPhase(){
		calculate(PHASEFOUND);
		return phase;
	}
}
