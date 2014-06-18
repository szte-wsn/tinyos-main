module Ad524xP{
	provides interface Write<uint8_t> as Write1;
	provides interface Write<uint8_t> as Write2;
	provides interface Get<uint8_t> as Get1;
	provides interface Get<uint8_t> as Get2;
	provides interface SplitControl;
	
	uses interface I2CPacket<TI2CBasicAddr>;
	uses interface BusPowerManager;
	uses interface Resource;
	uses interface GetNow<uint8_t> as GetAddress;
	uses interface DiagMsg;
	provides interface Init;
}
implementation{
	enum{
		COMMAND_WRITE1,
		COMMAND_WRITE2,
		COMMAND_SOFTRESET,
		
		STATUS_IDLE=0,
		STATUS_START,
		STATUS_STOP,
		STATUS_WRITE1,
		STATUS_WRITE12,
		STATUS_WRITE2,
		STATUS_WRITE21,
		STATUS_OUT1,
		STATUS_OUT2,
		
		DEFAULT_VALUE = 127,
	};
	
	typedef nx_struct{
		nx_bool isSecond:1;
		nx_bool softReset:1;
		nx_bool shutDown:1;
		nx_bool out1:1;
		nx_bool out2:1;
		nx_uint8_t dontCare:3;
		nx_uint8_t value;
	} ad524x_command_t;
	
	ad524x_command_t buffer;
	norace error_t lastError;
	norace uint8_t value1=DEFAULT_VALUE, value2=DEFAULT_VALUE;
	norace uint8_t status = STATUS_IDLE;
	norace bool out1=FALSE, out2=FALSE;
	bool isSoftShutDown=FALSE;
	bool powerReq=FALSE;
	
	command error_t Init.init(){
		call BusPowerManager.configure(1,1);
		return SUCCESS;
	}

	
	inline error_t write(uint8_t commandMode){
		if(commandMode == COMMAND_WRITE2){
			buffer.isSecond=TRUE;
			buffer.value = value2;
		} else {
			buffer.isSecond=FALSE;
			buffer.value = value1;
			if(commandMode == COMMAND_SOFTRESET){
				buffer.softReset = TRUE;
			}
		}
		buffer.out1 = out1;
		buffer.out2 = out2;
		buffer.shutDown = isSoftShutDown;
		return call I2CPacket.write(I2C_START | I2C_STOP, call GetAddress.getNow(), 2, (uint8_t*)&buffer);
	}
	
	//TODO: we only power on the sensor here, so earlier writes are lost, and probably causes driver bugs
	command error_t SplitControl.start(){
		if( out1 )
			return EALREADY;
		if( status != STATUS_IDLE )
			return EBUSY;
		out1 = TRUE;
		status = STATUS_START;
		if(!powerReq){
			powerReq = TRUE;
			call BusPowerManager.requestPower();
		}
		if(call BusPowerManager.isPowerOn()){
			return call Resource.request();
		} else
			return SUCCESS;
	}
	
	event void BusPowerManager.powerOn(){
		if( status == STATUS_START ){
			call Resource.request();
		}
	}
	
	command error_t SplitControl.stop(){
		if( !out1 )
			return EALREADY;
		if( status != STATUS_IDLE  )
			return EBUSY;
		out1 = FALSE;
		status = STATUS_STOP;
		return call Resource.request();
	}
	
	command uint8_t Get1.get(){
		return value1;
	}
	
	command uint8_t Get2.get(){
		return value2;
	}
	
	command error_t Write1.write(uint8_t newValue){
		if(status == STATUS_WRITE1 || status == STATUS_WRITE12 )
			return EALREADY;
		if( status != STATUS_IDLE && status != STATUS_WRITE2 )
			return EBUSY;
		value1 = newValue;
		if(status == STATUS_IDLE){
			status = STATUS_WRITE1;
			return call Resource.request();
		} else {
			status = STATUS_WRITE21;
			return SUCCESS;
		}
	}
	
	command error_t Write2.write(uint8_t newValue){
		if(status == STATUS_WRITE2 || status == STATUS_WRITE21 )
			return EALREADY;
		if( status != STATUS_IDLE && status != STATUS_WRITE1 )
			return EBUSY;
		value2 = newValue;
		if(status == STATUS_IDLE){
			status = STATUS_WRITE2;
			return call Resource.request();
		} else {
			status = STATUS_WRITE12;
			return SUCCESS;
		}
	}
	
	event void Resource.granted(){
		if(status == STATUS_WRITE2 || status == STATUS_WRITE21)
			atomic {
				write(COMMAND_WRITE2);
			}
		else
			atomic {
				write(COMMAND_WRITE1);
			}
	}
	
	task void signalWriteDone1(){
		signal Write1.writeDone(lastError, value1);
	}
	
	task void signalWriteDone2(){
		signal Write2.writeDone(lastError, value2);
	}
	
	task void signalStartDone(){
		signal SplitControl.startDone(lastError);
	}
	
	task void signalStopDone(){
		signal SplitControl.stopDone(lastError);
		powerReq = FALSE;
		call BusPowerManager.releasePower();
	}
	
	event void BusPowerManager.powerOff(){
	}
	
	async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
		lastError = error;
		atomic{
			switch(status){
				case STATUS_WRITE1:{
					status = STATUS_IDLE;
					post signalWriteDone1();
					call Resource.release();
				}break;
				case STATUS_WRITE2:{
					status = STATUS_IDLE;
					post signalWriteDone2();
					call Resource.release();
				}break;
				case STATUS_WRITE12:{
					status = STATUS_WRITE2;
					post signalWriteDone1();
					write(COMMAND_WRITE2);
				}break;
				case STATUS_WRITE21:{
					status = STATUS_WRITE1;
					post signalWriteDone2();
					write(COMMAND_WRITE1);
				}break;
				case STATUS_START:{
					status = STATUS_IDLE;
					post signalStartDone();
					call Resource.release();
				}break;
				case STATUS_STOP:{
					status = STATUS_IDLE;
					post signalStopDone();
					call Resource.release();
				}break;
			}
		}
	}
	
	async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){}
}