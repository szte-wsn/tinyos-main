module MicrophoneP{
	provides interface Read<uint16_t>;
	provides interface ReadStream<uint16_t>;
	uses interface Read<uint16_t> as SubRead;
	uses interface ReadStream<uint16_t> as SubReadStream;
	provides interface Write<uint16_t> as Amp1;
	provides interface Write<uint16_t> as Amp2;
	uses interface Write<uint16_t> as SubAmp1;
	uses interface Write<uint16_t> as SubAmp2;
	uses interface SplitControl as Amp1Control;
	uses interface SplitControl as Amp2Control;
	uses interface BusPowerManager as OpAmps;
	uses interface BusPowerManager as Mic;
	uses interface Timer<TMilli>;
	provides interface Init;
	
	provides interface Atm128AdcConfig;
	uses interface MicaBusAdc;
	
	uses interface DiagMsg;
}
implementation{
	error_t result;
	uint16_t amp1=0, amp2=0;
	uint32_t readVal;
	
	enum{
		POT_SETTING_TIMEOUT = 10,
		START = (1 << 0),
		MIC_POWER = (1 << 1),
		AMP_POWER = (1 << 2),
		POT0_POWER = (1 << 3),
		POT1_POWER = (1 << 4),
		POT0_VALUE = (1 << 5),
		POT1_VALUE = (1 << 6),
		STOP = (1 << 7),
		ALL_ON = MIC_POWER|AMP_POWER|POT0_POWER|POT1_POWER|POT0_VALUE|POT1_VALUE,
	};
	uint8_t turning = 0;
	uint8_t turnedOn = 0;
	bool micPowerReq=FALSE, opAmpPowerReq=FALSE;
	bool streamMode;
	
	inline void shutDown();
	inline void readDone();
	
	command error_t ReadStream.postBuffer(uint16_t* buf, uint16_t count){
		return call SubReadStream.postBuffer(buf, count);
	}
	
	event void SubReadStream.bufferDone(error_t err, uint16_t* buf, uint16_t count){
		signal ReadStream.bufferDone(err, buf, count);
	}
	
	task void amp1WriteDone(){
		signal Amp1.writeDone(SUCCESS, 128-amp1);
	}
	
	command error_t Amp1.write(uint16_t value){
		if(call DiagMsg.record()){
			call DiagMsg.str("1wr");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.uint16(value);
			call DiagMsg.send();
		}
		if( turnedOn == 0 ){
			if( value > 128 )
				value = 128;
			amp1 = 128 - value;
			post amp1WriteDone();
			return SUCCESS;
		} else if( streamMode && (turnedOn & ALL_ON) == ALL_ON && !(turnedOn & STOP)){
			if( value > 128 )
				value = 128;
			amp1 = 128 - value;
			return call SubAmp1.write(amp1);
		}
		return EBUSY;
	}
	
	task void amp2WriteDone(){
		signal Amp2.writeDone(SUCCESS, 128-amp2);
	}
	
	command error_t Amp2.write(uint16_t value){
		if(call DiagMsg.record()){
			call DiagMsg.str("2wr");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.uint16(value);
			call DiagMsg.send();
		}
		if( turnedOn == 0 ){
			if( value > 128 )
				value = 128;
			amp2 = 128 - value;
			post amp2WriteDone();
			return SUCCESS;
		} else if( streamMode && (turnedOn & ALL_ON) == ALL_ON && !(turnedOn & STOP)){
			if( value > 128 )
				value = 128;
			amp2 = 128 - value;
			return call SubAmp2.write(amp2);
		}
		return EBUSY;
	}
	
	task void shutDownTask(){
		shutDown();
	}
	
	inline void shutDown(){
		if(call DiagMsg.record()){
			call DiagMsg.str("sd");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		turnedOn |= STOP;
		turnedOn &= ~START;
		atomic{
			if(opAmpPowerReq){
				opAmpPowerReq = FALSE;
				call OpAmps.releasePower();
			}
		}
		atomic{
			if(micPowerReq){
				micPowerReq = FALSE;
				call Mic.releasePower();
			}
		}
		turnedOn &= ~MIC_POWER;
		turnedOn &= ~AMP_POWER;
		turning &= ~MIC_POWER;
		turning &= ~AMP_POWER;
		
		turnedOn &= ~POT0_VALUE; //these doesn't need to set back
		turnedOn &= ~POT1_VALUE;
		
		if(call DiagMsg.record()){
			call DiagMsg.str("pow/pot");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		
		if(turnedOn & POT0_POWER)
			call Amp1Control.stop();
		if(call DiagMsg.record()){
			call DiagMsg.str("amp0");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		if(turnedOn & POT1_POWER)
			call Amp2Control.stop();
		if(call DiagMsg.record()){
			call DiagMsg.str("amp1");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		if( (turning&ALL_ON) != 0 )
			;//post shutDownTask();
		else if((turnedOn&ALL_ON) == 0){
			readDone();
		}
	}
	
	event void Timer.fired(){
		if(call DiagMsg.record()){
			call DiagMsg.str("read");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		turning = 0;
		if(streamMode){
			call SubReadStream.read(readVal);
		} else {
			call SubRead.read();
		}
	}
	
	inline void readDone(){
		turnedOn = 0;
		if(streamMode){
			signal ReadStream.readDone(result, readVal);
		} else {
			signal Read.readDone(result, readVal);
		}
	}
	
	event void SubRead.readDone(error_t err, uint16_t val){
		readVal = val;
		result = err;
		shutDown();
	}
	
	event void SubReadStream.readDone(error_t err, uint32_t period){
		readVal = period;
		result = err;
		shutDown();
	}
	
	inline error_t start(){
		error_t err;
		if(call DiagMsg.record()){
			call DiagMsg.str("Req");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		if(turnedOn > 0 || turning > 0)
			return EBUSY;
		turnedOn = START;
		turning = START;
		result = SUCCESS;
		if(call DiagMsg.record()){
			call DiagMsg.str("OK");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		err = call Amp1Control.start();
		if(err == SUCCESS){
			turning |= POT0_POWER;
		} else if( err == EALREADY ){
			signal Amp1Control.startDone(SUCCESS);
		} else {
			return FAIL;
		}
		if(call DiagMsg.record()){
			call DiagMsg.str("amp1");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		err = call Amp2Control.start();
		if(err == SUCCESS){
			turning |= POT1_POWER;
		} else if( err == EALREADY ){
			signal Amp2Control.startDone(SUCCESS);
		} else {
			return FAIL;
		}
		if(call DiagMsg.record()){
			call DiagMsg.str("amp2");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		turning |= AMP_POWER|MIC_POWER;
		atomic{
			if(!opAmpPowerReq){
				opAmpPowerReq = TRUE;
				call OpAmps.requestPower();
			}
		}
		if(call DiagMsg.record()){
			call DiagMsg.str("opamp");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		atomic{
			if(!micPowerReq){
				micPowerReq = TRUE;
				call Mic.requestPower();
			}
		}
		if(call DiagMsg.record()){
			call DiagMsg.str("mic");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		if( call OpAmps.isPowerOn()){
			turning &= AMP_POWER;
			turnedOn |= AMP_POWER;
		}
		if(call DiagMsg.record()){
			call DiagMsg.str("opamp2");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		if( call Mic.isPowerOn()){
			turning &= MIC_POWER;
			turnedOn |= MIC_POWER;
		}
		if(call DiagMsg.record()){
			call DiagMsg.str("mic2");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		return SUCCESS;
	}
	
	command error_t Read.read(){
		error_t err = start();
		if( err == SUCCESS ){
			streamMode = FALSE;
		}
		return err;
	}
	
	command error_t ReadStream.read(uint32_t period){
		error_t err = start();
		if( err == SUCCESS ){
			streamMode = TRUE;
			readVal = period;
		}
		return err;
	}
	
	event void Amp1Control.startDone(error_t err){
		if(call DiagMsg.record()){
			call DiagMsg.str("amp0ok");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.uint8(err);
			call DiagMsg.send();
		}
		turning &= ~POT0_POWER;
		if( err == SUCCESS || err == EALREADY ){
			turnedOn |= POT0_POWER;
			err = call SubAmp1.write(amp1);
			if( err == SUCCESS || err == EALREADY ){
				turning |= POT0_VALUE;
			} else {
				result = FAIL;
				shutDown();
				return;
			}
			if(call DiagMsg.record()){
				call DiagMsg.str("pot0");
				call DiagMsg.hex8(turnedOn);
				call DiagMsg.hex8(turning);
				call DiagMsg.hex8(err);
				call DiagMsg.send();
			}
		} else {
			result = FAIL;
			shutDown();
		}
	}
	
	event void Amp2Control.startDone(error_t err){
		if(call DiagMsg.record()){
			call DiagMsg.str("amp1ok");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.uint8(err);
			call DiagMsg.send();
		}
		turning &= ~POT1_POWER;
		if( err == SUCCESS || err == EALREADY ){
			turnedOn |= POT1_POWER;
			err = call SubAmp2.write(amp2);
			if( err == SUCCESS || err == EALREADY ){
				turning |= POT1_VALUE;
			} else {
				result = FAIL;
				shutDown();
				return;
			}
			if(call DiagMsg.record()){
				call DiagMsg.str("pot1");
				call DiagMsg.hex8(turnedOn);
				call DiagMsg.hex8(turning);
				call DiagMsg.hex8(err);
				call DiagMsg.send();
			}
		} else {
			result = FAIL;
			//shutDown();
		}
	}
	
	event void SubAmp1.writeDone(error_t err, uint16_t val){
		if(call DiagMsg.record()){
			call DiagMsg.str("pot0ok");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.uint16(128-val);
			call DiagMsg.uint8(err);
			call DiagMsg.send();
		}
		if(!(turnedOn & POT0_VALUE)){
			turning &= ~POT0_VALUE;
			if( err == SUCCESS || err == EALREADY){
				turnedOn |= POT0_VALUE;
				if( (turnedOn & ALL_ON) == ALL_ON  )
					call Timer.startOneShot(POT_SETTING_TIMEOUT);
			} else {
				result = FAIL;
				shutDown();
			}
		} else
			signal Amp1.writeDone(err, 128-val);
	}
	
	event void SubAmp2.writeDone(error_t err, uint16_t val){
		if(call DiagMsg.record()){
			call DiagMsg.str("pot1ok");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.uint16(128-val);
			call DiagMsg.uint8(err);
			call DiagMsg.send();
		}
		if(!(turnedOn & POT1_VALUE)){
			turning &= ~POT1_VALUE;
			if( err == SUCCESS || err == EALREADY){
				turnedOn |= POT1_VALUE;
				if( (turnedOn & ALL_ON) == ALL_ON  )
					call Timer.startOneShot(POT_SETTING_TIMEOUT);
			} else {
				result = FAIL;
				shutDown();
			}
		} else
			signal Amp2.writeDone(err, 128-val);
	}
	
	event void OpAmps.powerOn(){
		if(call DiagMsg.record()){
			call DiagMsg.str("opampok");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.hex8(ALL_ON);
			call DiagMsg.send();
		}
		turning &= ~AMP_POWER;
		turnedOn |= AMP_POWER;
		if( (turnedOn & ALL_ON) == ALL_ON  )
			call Timer.startOneShot(POT_SETTING_TIMEOUT);
	}
	
	event void Mic.powerOn(){
		if(call DiagMsg.record()){
			call DiagMsg.str("micok");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.send();
		}
		turning &= ~MIC_POWER;
		turnedOn |= MIC_POWER;
		if( (turnedOn & ALL_ON) == ALL_ON  )
			call Timer.startOneShot(POT_SETTING_TIMEOUT);
	}
	
	event void Amp1Control.stopDone(error_t err){
		if(call DiagMsg.record()){
			call DiagMsg.str("amp0off");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.uint8(err);
			call DiagMsg.send();
		}
		turning &= ~POT0_POWER;
		turnedOn &= ~POT0_POWER;
		if( (turnedOn & ALL_ON) == 0 )
			readDone();
	}
	
	event void Amp2Control.stopDone(error_t err){
		if(call DiagMsg.record()){
			call DiagMsg.str("amp1off");
			call DiagMsg.hex8(turnedOn);
			call DiagMsg.hex8(turning);
			call DiagMsg.uint8(err);
			call DiagMsg.send();
		}
		turning &= ~POT1_POWER;
		turnedOn &= ~POT1_POWER;
		if( (turnedOn & ALL_ON) == 0 )
			readDone();
	}
	
	command error_t Init.init(){
		call Mic.configure(200, 200);//TODO it's a guess...
		call OpAmps.configure(10, 10); //it's probably way faster, but we have much slower stuffs, and better safe than sorry
		return SUCCESS;
	}
	
	event void Mic.powerOff(){}
	event void OpAmps.powerOff(){}
	
	async command uint8_t Atm128AdcConfig.getChannel() {
		return call MicaBusAdc.getChannel();
	}

	async command uint8_t Atm128AdcConfig.getRefVoltage() {
		#ifdef PLATFORM_IRIS
		return ATM128_ADC_VREF_AVCC;
		#else
		return ATM128_ADC_VREF_AVDD;
		#endif
	}

	async command uint8_t Atm128AdcConfig.getPrescaler() {
		return ATM128_ADC_PRESCALE;
	}
	
	default event void ReadStream.bufferDone(error_t err, uint16_t* buf, uint16_t count){}
	default event void ReadStream.readDone(error_t err, uint32_t period){}
	default event void Read.readDone(error_t err, uint16_t val){}
}