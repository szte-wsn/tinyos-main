module MeasureWaveC{
	provides interface MeasureWave;
	
	uses interface DiagMsg;
}
implementation{
	
	command uint16_t MeasureWave.getStart(uint8_t *data, uint16_t len, uint8_t amplitudeThreshold, uint8_t timeThreshold){
		uint16_t i=0;
		uint8_t count = 0;
		while( i<len ){
			if( *(data+i) >= amplitudeThreshold ){
				if( ++count > timeThreshold)
					break;
			} else
				count = 0;
			i++;
		}
		if(call DiagMsg.record()){
			call DiagMsg.chr('S');
			call DiagMsg.uint16(i-timeThreshold);
			call DiagMsg.send();
		}
		return i-timeThreshold;
	}
	
	void filter(uint8_t *input, uint8_t *output, uint16_t len, uint8_t filterlen){
		uint16_t i;
		uint8_t tempvalue = 0;
		for(i=0;i<filterlen;i++){
			tempvalue += *(input+i);
			*(output+i) = tempvalue;
		}
		for(i=filterlen; i<len; i++){
			tempvalue += *(input+i);
			tempvalue -= *(input+i-filterlen);
			*(output+i) = tempvalue;
		}
	}
	
	command void MeasureWave.filter(uint8_t *data, uint16_t len, uint8_t filterlen, uint8_t count){
		uint8_t tempbuf[len];//FIXME this should be global, it's way too big for stack
		uint8_t i;
		uint8_t *input = data, *output = tempbuf;
		for(i=0;i<count;i++){
			uint8_t *swap = input;
			filter(input, output, len, filterlen);
			input = output;
			output = swap;
		}
		if( output == data ){ //this is the next output, so the real data is in the temp buffer. copy it
			memcpy(data, tempbuf, len);
		}
	}
	
	
	command uint16_t MeasureWave.getPeriod(uint8_t *data, uint16_t len, uint8_t *average){
		uint16_t i;
		uint32_t temp;
		uint16_t crossingCount = 0;
		uint16_t lastCrossing = 0;
		
		
		//first, calculate the average
		temp = 0;
		for(i=0;i<len;i++){
			temp += *(data+i);
		}
		*average = temp/len;
		
		if(call DiagMsg.record()){
			call DiagMsg.chr('A');
			call DiagMsg.uint16(*average);
			call DiagMsg.uint16(len);
			call DiagMsg.send();
		}
		
		i = 0;
		temp = 0;
		
		//we only search for RISING crossings
		
		while(  i<len && *(data+i) >= (*average - 1) )
			i++;
		
		if(call DiagMsg.record()){
			call DiagMsg.chr('F');
			call DiagMsg.uint16(i);
			call DiagMsg.send();
		}

		
		while( i<len ){
			//search the next crossing
			while( i<len && *(data+i) < *average )
				i++;
			
			if(call DiagMsg.record()){
				call DiagMsg.chr('X');
				call DiagMsg.uint16(i);
				call DiagMsg.uint16(lastCrossing);
				call DiagMsg.uint16(crossingCount);
				call DiagMsg.uint32(temp);
				call DiagMsg.send();
			}
			
			if( i<len ){ //new crossing point
				if( crossingCount!=0 ){
					temp += (i-lastCrossing);
				}
				crossingCount++;
				lastCrossing = i;
				while(  i<len && *(data+i) >= (*average - 1) ) //go through the upper half period, and a bit more, to avoid oscillation near the average
					i++;
			}
			
			if(call DiagMsg.record()){
				call DiagMsg.chr('Z');
				call DiagMsg.uint16(i);
				call DiagMsg.send();
			}
		}
		if( crossingCount > 1 )
			return temp/(crossingCount-1);
		else
			return 0;
	}
	
	inline static uint8_t getPhaseWindowLimit(uint8_t period, uint8_t phaseWindows, uint8_t number){
		uint8_t ret = number*period/phaseWindows;
		if( ret > period )
			return ret - period;
		else
			return ret;
	}
	
	command uint16_t MeasureWave.getPhase(uint8_t *data, uint16_t len, uint16_t offset, uint16_t period, uint8_t zeroPoint){
		#define PHASE_WINDOWS 4
		#define PHASE_WINDOW_OVERLAP 2
		uint16_t i = offset;
		uint16_t end = (((uint32_t)period*period)>>2)+offset;
		uint32_t temp[PHASE_WINDOWS] = {0,0,0,0};
		uint16_t count[PHASE_WINDOWS] = {0,0,0,0};
		
		if( end<len ){ //move the window to the middle of the sample
			uint16_t offset2 = (len - end) >> 1;
			end+=offset2;
			i+=offset2;
		} else {
			end = len;
		}
		
		if(call DiagMsg.record()){
			call DiagMsg.chr('h');
			call DiagMsg.uint16(i);
			call DiagMsg.uint16(end);
			call DiagMsg.uint16(getPhaseWindowLimit(period, PHASE_WINDOWS, 0));
			call DiagMsg.uint16(getPhaseWindowLimit(period, PHASE_WINDOWS, 1));
			call DiagMsg.uint16(getPhaseWindowLimit(period, PHASE_WINDOWS, 2));
			call DiagMsg.uint16(getPhaseWindowLimit(period, PHASE_WINDOWS, 3));
			call DiagMsg.uint16(getPhaseWindowLimit(period, PHASE_WINDOWS, 4));
			call DiagMsg.uint16(getPhaseWindowLimit(period, PHASE_WINDOWS, 5));
			call DiagMsg.uint16(getPhaseWindowLimit(period, PHASE_WINDOWS, 6));
			call DiagMsg.send();
		}
		
		while(  i<len && *(data+i) >= (zeroPoint - 1) )
			i++;
		
		while(i<end){
			while( i<end && *(data+i) < zeroPoint )
				i++;
			
			if( i<end ){ //new crossing point
				uint8_t j;
				uint16_t phase = i - offset;
				phase = phase % period;
				for(j=0;j<PHASE_WINDOWS-1;j++){
					if( phase > getPhaseWindowLimit(period, PHASE_WINDOWS, j) && phase <= getPhaseWindowLimit(period, PHASE_WINDOWS, j+PHASE_WINDOW_OVERLAP)){
						temp[j]+=phase;
						count[j]++;
						if(call DiagMsg.record()){
							call DiagMsg.chr('H');
							call DiagMsg.uint16(i);
							call DiagMsg.uint16(phase);
							call DiagMsg.uint8(j);
							call DiagMsg.uint16s(count, PHASE_WINDOWS);
							call DiagMsg.uint16(temp[j]);
							call DiagMsg.send();
						}
					}
				}
				if( phase > getPhaseWindowLimit(period, PHASE_WINDOWS, PHASE_WINDOWS-1) || phase <= getPhaseWindowLimit(period, PHASE_WINDOWS, PHASE_WINDOWS-1+PHASE_WINDOW_OVERLAP)){
					temp[PHASE_WINDOWS-1]+=phase;
					count[PHASE_WINDOWS-1]++;
					if(call DiagMsg.record()){
						call DiagMsg.chr('H');
						call DiagMsg.uint16(i);
						call DiagMsg.uint16(phase);
						call DiagMsg.uint8(j);
						call DiagMsg.uint16s(count, PHASE_WINDOWS);
						call DiagMsg.uint32(temp[PHASE_WINDOWS-1]);
						call DiagMsg.send();
					}
				}
				
				while(  i<end && *(data+i) >= (zeroPoint - 1) ) //go through the upper half period, and a bit more, to avoid oscillation near the zeroPoint
					i++;
			}
		}
		
		end = 0; //reuse variable for maximum search
		for(i=1;i<PHASE_WINDOWS;i++){
			if( count[i] > count[end] ){
				end = i;
			}
		}
		if(call DiagMsg.record()){
			call DiagMsg.chr('F');
			call DiagMsg.uint8(end);
			call DiagMsg.uint16s(count, PHASE_WINDOWS);
			call DiagMsg.uint32(temp[end]);
			call DiagMsg.uint16(temp[end]/count[end]);
			call DiagMsg.send();
		}
		return temp[end]/count[end];
	}
}