module ProcessP{
	provides interface Process;
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
		uint16_t firstMin;
	} measurement_t;
	
	measurement_t measurement;
	
	void init() {
	  uint16_t i=0;
	  for(i=0; i<128; i++) 
	    measurement.temp[i] = 0;
	  measurement.start = 0;
	  measurement.tempcnt = 0;
	  measurement.mintresh = 0;
	  measurement.absmin = 250;
	  measurement.absminind = 0;
	  measurement.absmax = 0;
	  measurement.absmaxind = 0;
	  measurement.minstartind = 0;
	  measurement.minendind = 0;
	  measurement.state = 0;
	  measurement.firstMin = 0;
	  for(i=0; i<20; i++) {
	    measurement.minstart[i] = 0;
	    measurement.minend[i] = 0;
	  }
	  measurement.period = 0;
	  measurement.phase = 0;
	}
	
	void filtering() {
	  uint16_t i = 0;
	  for(i=measurement.start;i<measurement.len-4;i+=4){
			measurement.temp[measurement.tempcnt++] = (measurement.data[i]+measurement.data[i+1]+measurement.data[i+2]+measurement.data[i+3])>>2;
			if(measurement.tempcnt >= 128)
			  break;
		}  
	}
	
	command void Process.changeData(uint8_t *data, uint16_t len, uint8_t threshold, uint8_t leadTime){
		measurement.data = data;
		measurement.len = len;
		measurement.startTreshold = threshold;
		init();
	}
	
	void getStartPoint() {
	  uint16_t i = 0;
	  for(i=10; i<measurement.len-1; i++) {
	    if(measurement.data[i]>measurement.startTreshold){
	      measurement.start = i;
	      break;
	    }
	  }
	  filtering();
	}
	
	void getAmplitude() {
	  uint16_t i = 0;
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
	  uint16_t i = 0;
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
			int firstindex = (measurement.minstart[0]+measurement.minend[0])>>1;
			int secondindex = (measurement.minstart[1]+measurement.minend[1])>>1;
			int period = secondindex-firstindex;
			//Period: period * 4, because of the filter
			if(period > 0x00FF) 
			  measurement.period = 0xFF;
			else if(period < 0)
			  measurement.period = 0;
			else
			  measurement.period = period & 0x00FF;
			if(measurement.firstMin > 0x00FF)
			  measurement.firstMin = 0x00FF;
			else 
			  measurement.firstMin = firstindex & 0x00FF;
		}else if(measurement.minendind>=3){
			int firstindex = (measurement.minstart[0]+measurement.minend[0])>>1;
			int secondindex = (measurement.minstart[1]+measurement.minend[1])>>1;	
			int thirdindex = (measurement.minstart[2]+measurement.minend[2])>>1;
			int period1 = secondindex-firstindex;
			int period2 = thirdindex-secondindex;
  		//the final period value is the avarage of the two periods
  		if(((period1+period2)>>1) > 0x00FF) 
  		  measurement.period = 0xFF;
  		else if(((period1+period2)>>1) < 0) 
  		  measurement.period = 0;
			else
			  measurement.period = ((period1+period2)>>1) & 0x00FF;
			if(measurement.firstMin > 0x00FF)
			  measurement.firstMin = 0x00FF;
			else
			  measurement.firstMin = firstindex & 0x00FF;
		}
	}
	
	void getPhase() {
	  if(measurement.firstMin >= 0x00FF)
		  measurement.phase = 0x000F;
	  else if(measurement.firstMin >= measurement.period)
	    measurement.phase = measurement.firstMin - measurement.period;
	  else if(measurement.firstMin < 0)
	    measurement.phase = 0;
	  else
	    measurement.phase = measurement.firstMin;
	}
	
	command uint8_t Process.getStartPoint(){
	  getStartPoint();
		return measurement.start;
	}
	
	command uint8_t Process.getMinAmplitude() {
	  getAmplitude();
	  return measurement.absmin;
	}
	
	command uint8_t Process.getMaxAmplitude() {
	  getAmplitude();
	  return measurement.absmax;
	}
	
	command uint16_t Process.getPeriod() {
	  getPeriod();
	  return measurement.period;
	}
	
	command uint8_t Process.getPhase() {
	  getPhase();
	  return measurement.phase;
	}
	
}
