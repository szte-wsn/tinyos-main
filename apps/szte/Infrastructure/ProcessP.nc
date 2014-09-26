module ProcessP{
	provides interface MeasureWave;
}
implementation{
  typedef struct measurement_t{
    uint8_t *data;
    uint8_t len;
    uint8_t temp[128];
    uint8_t tempcnt;
		uint8_t start;
		uint8_t absmin;
		uint8_t absminind;
		uint8_t absmax;
		uint8_t absmaxind;
		uint8_t mintresh;
		uint8_t startTreshold;
		uint8_t minstart[20];
		uint8_t minstartind;
		uint8_t minend[20];
		uint8_t minendind;
		uint16_t period;
		uint8_t phase;
		uint8_t state;
		uint8_t firstMin;
	} measurement_t;
	
	measurement_t measurement;
	
	void init() {
	  measurement.start = 0;
	  measurement.tempcnt = 0;
	  measurement.absmin = 250;
	  measurement.absminind = 0;
	  measurement.absmax = 0;
	  measurement.absmaxind = 0;
	  measurement.minstartind = 0;
	  measurement.minendind = 0;
	  measurement.state = 0;
	  measurement.firstMin = 0;
	  measurement.mintresh = 0;
	  measurement.period = 0;
	  measurement.phase = 0;
	}
	
	command void MeasureWave.changeData(uint8_t *data, uint16_t len, uint8_t threshold, uint8_t leadTime){
		measurement.data = data;
		measurement.len = len;
		measurement.startTreshold = threshold;
		init();
	}
		
	void filtering() {
	  uint16_t i = 0;
	  for(i=measurement.start;i<measurement.len-4;i+=4){
			measurement.temp[measurement.tempcnt++] = (measurement.data[i]+measurement.data[i+1]+measurement.data[i+2]+measurement.data[i+3])>>2;
			if(measurement.tempcnt >= 128)
			  break;
		}  
	}
	
	void getStartPoint() {
	  uint16_t i = 0;
	  for(i=10; i<measurement.len-1; i++) {
	    if(i<255 && measurement.data[i]>measurement.startTreshold){
	      measurement.start = i;
	      break;
	    } else if(i>=255) {
	      measurement.start = 0xF;
	      break;
	    }
	  }
	  filtering();
	}
	
	void getAmplitude() {
	  uint8_t i = 0;
	  for(i=10; i<measurement.tempcnt>>1; i++){
			if(measurement.temp[i]<measurement.absmin){
				measurement.absmin = measurement.temp[i];
				measurement.absminind = i;
			}
			if(measurement.temp[i]>measurement.absmax){
				measurement.absmax = measurement.temp[i];
				measurement.absmaxind = i;
			}
		}
		measurement.mintresh=measurement.absmin+((measurement.absmax-measurement.absmin)>>2);
	}
	
	void getPeriod() {
	  uint8_t i = 0;
	  for(i=10; i<measurement.tempcnt-2; i++){
			if(measurement.state == 0 && measurement.temp[i]<=measurement.mintresh){
				measurement.state = 1;
				measurement.minstart[measurement.minstartind++] = i;
			}
			if(measurement.state == 1 && measurement.temp[i]>measurement.mintresh){
				measurement.state = 0;
				measurement.minend[measurement.minendind++] = i-1;
			}
			if((measurement.minstartind >= 20) && (measurement.minendind >= 20))
			  break;
		}
		if(measurement.minendind<3 && measurement.minendind>0){
			uint8_t firstindex = (measurement.minstart[0]+measurement.minend[0])>>1;
			uint8_t secondindex = (measurement.minstart[1]+measurement.minend[1])>>1;
			uint8_t period = secondindex-firstindex;
			//Period: period * 4, because of the filter
			if(period*4 >= 0xFF) 
			  measurement.period = 0xFF;
			else if(period <= 0)
			  measurement.period = 0;
			else
			  measurement.period = period*4 & 0xFF;
			if(firstindex >= 0xF)
			  measurement.firstMin = 0xF;
			else if(firstindex <= 0)
			  measurement.firstMin = 0;
			else 
			  measurement.firstMin = firstindex & 0xF;
		}else if(measurement.minendind>=3){
			uint8_t firstindex = (measurement.minstart[0]+measurement.minend[0])>>1;
			uint8_t secondindex = (measurement.minstart[1]+measurement.minend[1])>>1;	
			uint8_t thirdindex = (measurement.minstart[2]+measurement.minend[2])>>1;
			uint8_t period1 = secondindex-firstindex;
			uint8_t period2 = thirdindex-secondindex;
  		//the final period value is the avarage of the two periods
  		if(((period1+period2)>>1)*4 >= 0xFF) 
  		  measurement.period = 0xFF;
  		else if(((period1+period2)>>1) <= 0) 
  		  measurement.period = 0;
			else
			  measurement.period = ((period1+period2)>>1)*4 & 0xFF;
			if(firstindex >= 0xF)
			  measurement.firstMin = 0xF;
			else if(firstindex <= 0)
			  measurement.firstMin = 0;
			else
			  measurement.firstMin = firstindex & 0xF;
		} else {
		  measurement.period = 1;
		}
	}
	
	void getPhase() {
	  if(measurement.firstMin >= 0xF)
		  measurement.phase = 0xF;
	  else if(measurement.firstMin <= 0)
	    measurement.phase = 0;
	  else
	    measurement.phase = measurement.firstMin && 0xF;
	}
	
	command uint8_t MeasureWave.getPhaseRef(){
	  getStartPoint();
		return measurement.start;
	}
	
	command uint8_t MeasureWave.getMinAmplitude() {
	  getAmplitude();
	  return measurement.absmin;
	}
	
	command uint8_t MeasureWave.getMaxAmplitude() {
	  getAmplitude();
	  return measurement.absmax;
	}
	
	command uint16_t MeasureWave.getPeriod() {
	  getPeriod();
		if( measurement.period == 0 )
			return 1;
		else
			return measurement.period;
	}
	
	command uint8_t MeasureWave.getPhase() {
	  getPhase();
		if( measurement.period == 0 )
			return 1;
		else
			return measurement.phase;
	}
	
}
