module MeasureWaveP{
	provides interface MeasureWave;
	
	uses interface DiagMsg;
}
implementation{
	//consts to configure the calculation algorithm
	enum{
		DROPFIRST=10,//the first DROPFIRST measure will be dropped before phaseref search
		DROPSECOND=40,//the filter/period/phase algorithm will search with phaseRef+DROPSECOND startpoint
		DROPEND=2,//the filter/period/phase algorithm will search with phaseRef+DROPSECOND startpoint
		THRESHOLD=2,//phaseref will be the first point after DROPFIRST, where the measurement is above THRESHOLD
		FILTERWINDOW=5,//lenth of the filter window
		MINPOINTS=4,//how many minimum point will be searched for period calculation (it might found less)
		MINTRESH_RATIO=3,
	};
	
	#define TEMP_BUFFER_LEN 480
	
	enum{
		START = 0,
		REFFOUND = 1, 
		FILTERED = 2,
		MINMAXFOUND = 3,
		PERIODFOUND = 4,
		PHASEFOUND = 5,
		
		ERRORSTART = 16,
		NOPHASE = 17,
		NOPERIOD = 18,
		NOMINMAX = 19,
		NODATA = 20,
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
	uint16_t calcLen;
	uint8_t state;
	uint8_t temp[TEMP_BUFFER_LEN];

	
	void debugData(uint8_t lead, uint8_t *debugdata, uint16_t debuglen){
		#ifdef DEBUG_FILTER
		uint16_t offset=0;
		if (call DiagMsg.record()){
			call DiagMsg.str("---------");
			call DiagMsg.uint8(lead);
			call DiagMsg.uint16(debuglen);
			call DiagMsg.send();
		}
		while(offset<debuglen){
			if (call DiagMsg.record()){
				call DiagMsg.hex16(offset);
				if(offset+8<debuglen)
					call DiagMsg.hex8s((&debugdata[offset]),8);
				else
					call DiagMsg.hex8s((&debugdata[offset]),debuglen-offset);
				offset+=8;
				if(offset+8<debuglen)
					call DiagMsg.hex8s((&debugdata[offset]),8);
				else if(offset<debuglen)
					call DiagMsg.hex8s((&debugdata[offset]),debuglen-offset);
				call DiagMsg.send();
			}
// 			offset+=16;
			if(offset < 16 )
				offset=(debuglen/16)*15;
			else
				offset+=8;
		}
		#endif
	}
	
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
	
	void getPhaseRef(){
		uint8_t old;
	  phaseRef = DROPFIRST;
		calcEnd = len-DROPEND;
		old = data[calcEnd];
		data[calcEnd] = THRESHOLD;
		while( data[phaseRef] < THRESHOLD ){
			phaseRef++;
		}
		data[calcEnd] = old;
		calcStart = phaseRef+DROPSECOND;
		calcLen = calcEnd - calcStart;
		if(calcStart < calcEnd)
			state = REFFOUND;
		else
			state = NODATA;
	}
	
	void filter(){
		enum{
			halfwindow = (FILTERWINDOW>>1)+1,
		};
		uint8_t *input=&(data[calcStart]);
		uint16_t i;
		uint8_t tempvalue;
		
		debugData(0, input, calcLen);
		//first stage input->temp
		tempvalue = 0;
		for(i=0;i<halfwindow;i++){
			tempvalue += input[i];
		}
		temp[0] = tempvalue;
		calcLen-=halfwindow-1;
		for(i=0; i<calcLen-1; i++){
			tempvalue += input[i+halfwindow];
			tempvalue -= input[i];
			temp[i+1] = tempvalue;
		}
		debugData(1, temp, calcLen);
		//second stage, temp->input min/max search
		tempvalue = 0;
		for(i=0;i<halfwindow;i++){
			tempvalue += temp[i];
		}
		calcLen-=halfwindow-1;
		input[0]=tempvalue;
		minAmplitude = tempvalue;
		maxAmplitude = tempvalue;
		for(i=0; i<calcLen-1; i++){
			tempvalue += temp[i+halfwindow];
			tempvalue -= temp[i];
			input[i+1] = tempvalue;
			if( tempvalue < minAmplitude ){
				minAmplitude = tempvalue;
			}if( tempvalue > maxAmplitude )
				maxAmplitude = tempvalue;
		}
		debugData(2, input, calcLen);
		
    //HACK just for debug
// 		for(i=calcLen;i<len;i++){
// 			data[i]=minAmplitude+(maxAmplitude-minAmplitude)/MINTRESH_RATIO;
// 		}
		//end of HACK
		
		calcEnd = calcStart+calcLen;
		if(minAmplitude < maxAmplitude)
			state = MINMAXFOUND;
		else
			state = NOMINMAX;
	}
	
	//this function is inactive! it's done in the filter()
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
					//HACK just for debug
					data[firstMin]=255;
					//end of HACK
				} else {
					lastMin = (minStart+i)>>1;
					//HACK just for debug
					data[lastMin]=255;
					//end of HACK
				}
				#ifdef DEBUG_MEASUREWAVE
				if(call DiagMsg.record()){
					call DiagMsg.chr('M');
					call DiagMsg.uint8(minsFound);
					call DiagMsg.uint16(minStart);
					call DiagMsg.uint16(i);
					call DiagMsg.uint16(firstMin);
					call DiagMsg.uint16(lastMin);
					call DiagMsg.send();
				}
				#endif
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
		if( state >=NODATA )
			return 1;
		else
			return phaseRef;
	}
	
	command void MeasureWave.filter(){
		calculate(FILTERED);
	}
	
	command uint8_t MeasureWave.getMinAmplitude(){
		calculate(MINMAXFOUND);
		if( state >= NOMINMAX )
			return 1;
		else
			return minAmplitude;
	}
	
	command uint8_t MeasureWave.getMaxAmplitude(){
		calculate(MINMAXFOUND);
		if( state >= NOMINMAX )
			return 1;
		else
			return maxAmplitude;
	}
	
	command uint16_t MeasureWave.getPeriod(){
		calculate(PERIODFOUND);
		if( state >= NOPERIOD )
			return 1;
		else
			return period;
	}
	
	command uint8_t MeasureWave.getPhase(){
		calculate(PHASEFOUND);
		if( state >= NOPHASE )
			return 1;
		else
			return phase;
	}
}
