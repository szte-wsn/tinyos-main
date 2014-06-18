module AcousticInterruptP{
	provides interface SplitControl;
	provides interface AcousticInterrupt;
	uses interface SplitControl as SubControl;
	uses interface BusPowerManager as MicPowerManager;
	uses interface Write<uint8_t> as WriteAmp;
	uses interface Write<uint8_t> as WriteTh;
	uses interface Get<uint8_t> as GetAmp;
	uses interface Get<uint8_t> as GetTh;
	uses interface GpioInterrupt;
	uses interface Timer<TMilli>;
}
implementation{
	bool powerRequested=FALSE;
	uint8_t amp=127, th=127;
	uint16_t dep=100;
	error_t lastError;
	
	enum{
		STATE_OFF,
		STATE_TURNON_0,
		STATE_TURNON_1,
		STATE_TURNON_2,
		STATE_TURNON_3,
		STATE_IDLE,
		STATE_WRTIE1,
		STATE_WRITE2,
		STATE_WRITE_DONE,
		STATE_INT,
		STATE_INT_DEPRELL,
		STATE_INT_DEPRELL_OFF,
		STATE_TURNON_FAIL,
		STATE_WRITE_FAIL,
		STATE_TURNOFF,
	};
	
	norace uint8_t state=STATE_OFF;
	
	command error_t SplitControl.start(){
		error_t err;
		if(state!=STATE_OFF)
			return EALREADY;
		if(!powerRequested){
			powerRequested=TRUE;
			call MicPowerManager.requestPower();
		}
		
		err = call SubControl.start();
		if(err == SUCCESS){
			if(call MicPowerManager.isPowerOn()){
				state = STATE_TURNON_1;
			} else {
				state = STATE_TURNON_0;
			}
		}
		return err;
	}
	
	event void SubControl.startDone(error_t err){
		if( err != SUCCESS ){
			signal SplitControl.startDone(err);
		} else {
			state++;
			call WriteAmp.write(amp);
			call WriteTh.write(th);
		}
	}
	
	event void MicPowerManager.powerOn(){
		if( ++state == STATE_IDLE ){
			signal SplitControl.startDone(SUCCESS);
		}
	}
	
	event void WriteAmp.writeDone(error_t err, uint8_t val){
		if(state <= STATE_IDLE){
			if(err == SUCCESS){
				atomic{
					if( ++state == STATE_IDLE ){
						signal SplitControl.startDone(SUCCESS);
					}
				}
			} else {
				state = STATE_TURNON_FAIL;
				call SubControl.stop();
			}
		} else {
			if( ++state == STATE_WRITE_DONE ){ //TODO error handling
				lastError = ecombine(lastError, err);
				state = STATE_IDLE;
				signal AcousticInterrupt.setDone(lastError, call GetAmp.get(), call GetTh.get(), dep);
			}
		}
	}
	
	event void WriteTh.writeDone(error_t err, uint8_t val){
		if(state <= STATE_IDLE){
			if(err == SUCCESS){
				atomic{
					if( ++state == STATE_IDLE ){
						signal SplitControl.startDone(SUCCESS);
					}
				}
			} else {
				state = STATE_TURNON_FAIL;
				call SubControl.stop();
			}
		} else {
			if( ++state == STATE_WRITE_DONE ){
				lastError = ecombine(lastError, err);
				state = STATE_IDLE;
				signal AcousticInterrupt.setDone(lastError, call GetAmp.get(), call GetTh.get(), dep);
			}
		}
	}
	
	command error_t SplitControl.stop(){
		if(state == STATE_OFF )
			return EALREADY;
		else if(state != STATE_IDLE)
			return EBUSY;
		
		state = STATE_TURNOFF;
		return call SubControl.stop();
	}
	
	event void SubControl.stopDone(error_t err){
		uint8_t prevState = state;
		powerRequested = FALSE;
		call MicPowerManager.releasePower();
		state = STATE_OFF;
		if( prevState == STATE_TURNON_FAIL ){
			signal SplitControl.startDone(FAIL);
		} else {
			signal SplitControl.stopDone(err);
		}
	}
	
	task void signalSetDone(){
		signal AcousticInterrupt.setDone(SUCCESS, amp, th, dep);
	}
	
	command error_t AcousticInterrupt.set(uint8_t amplification, uint8_t threshold, uint16_t deprell){
		if(amp == amplification && th == threshold){
			return EALREADY;
		} else if (state > STATE_IDLE){
			return EBUSY;
		}
		
		if( state >= STATE_IDLE){
			state = STATE_WRTIE1;
			amp = amplification;
			th = threshold;
			dep = deprell;
			lastError = call WriteAmp.write(amp);
			if(lastError == SUCCESS){
				lastError = call WriteTh.write(th);
				if(lastError != SUCCESS)
					state++;
				return SUCCESS;
			} else
				return lastError;
		} else {
			amp = amplification;
			th = threshold;
			dep = deprell;
			post signalSetDone();
		}
		return SUCCESS;
	}
	
	async command error_t AcousticInterrupt.enable(){
		if( state < STATE_IDLE )
			return EOFF;
		else if( state != STATE_IDLE)
			return EBUSY;
		state = STATE_INT;
		return call GpioInterrupt.enableRisingEdge();
	}
	
	async command error_t AcousticInterrupt.disable(){
		if( state != STATE_INT && state != STATE_INT_DEPRELL)
			return EALREADY;
		else if( state == STATE_INT_DEPRELL ){
			state = STATE_INT_DEPRELL_OFF;
			return SUCCESS;
		}else
			return call GpioInterrupt.disable();
	}
	
	task void timerStart(){
		call Timer.startOneShot(dep);
	}
	
	event void Timer.fired(){
		if( state == STATE_INT_DEPRELL )
			call GpioInterrupt.enableRisingEdge();
		else //if( state == STATE_INT_DEPRELL_OFF )
			state = STATE_IDLE;
	}
	
	async event void GpioInterrupt.fired(){
		call GpioInterrupt.disable();
		state = STATE_INT_DEPRELL;
		post timerStart();
		signal AcousticInterrupt.fired();
	}
	
	event void MicPowerManager.powerOff(){}
	
	default event void AcousticInterrupt.setDone(error_t err, uint8_t amplification, uint8_t threshold, uint16_t deprell){}
	
}