generic module Mcp4x3_5xP(uint8_t potPowerAddress, uint8_t potValueAddress, bool dontSleep, bool dontturnoff)//TODO dontturnoff?
{
	provides interface Write<uint16_t>;
	provides interface Read<uint16_t>;
	provides interface SplitControl;
	
	uses interface Resource;
	
	//these two interfaces connects the two potmeter module
	uses interface GetNow<uint8_t> as OtherTCONPart;
	provides interface GetNow<uint8_t> as MyTCONPart;

	uses interface BusPowerManager as SelfPower;
	provides interface Init;
	uses interface StdControl;
	
	uses interface DiagMsg;
	uses interface Mcp4x3_5xCommunication;
}
implementation
{
	task void signalDone();
	
	enum{
		MCP_4x3_5x_STATE_IDLE = 0,
		MCP_4x3_5x_STATE_START = 1,
		MCP_4x3_5x_STATE_STOP = 2,
		MCP_4x3_5x_STATE_READ = 3,
		MCP_4x3_5x_STATE_WRITE = 4,
		MCP_4x3_5x_COMMAND_WRITE = 0,
// 		MCP_4x3_5x_COMMAND_INCREMENT = 1,
// 		MCP_4x3_5x_COMMAND_DECREMENT = 2,
		MCP_4x3_5x_COMMAND_READ = 3,
		MCP_4x3_5x_POWER_MASK = 0x0f,
		MCP_4x3_5x_POWER_ON = MCP_4x3_5x_POWER_MASK,
		MCP_4x3_5x_POWER_OFF = 0,
		MCP_4x3_5x_TCON_ADDR = 0x04,
		MCP_4x3_5x_MSB_MASK = 0x0100,
		MCP_4x3_5x_LSB_MASK = 0x00ff,
	};
	
	uint8_t buffer[2];
	bool selfPowerRequested = FALSE;
	norace uint8_t state = MCP_4x3_5x_STATE_IDLE;
	norace uint8_t power = MCP_4x3_5x_POWER_ON;
	norace error_t result;
	
	async command uint8_t MyTCONPart.getNow(){
		return (power & MCP_4x3_5x_POWER_MASK) << potPowerAddress;
	}
	
	command error_t Init.init(){
		call SelfPower.configure(100, 100);//this should be 20us, but it's somehow way too short
		if( dontSleep ){
			selfPowerRequested = TRUE;
			call SelfPower.requestPower();
		}
		return SUCCESS;
	}
	
	event void SelfPower.powerOn(){
		if(call DiagMsg.record()){
			call DiagMsg.str("pon");
			call DiagMsg.uint8(potValueAddress);
			call DiagMsg.uint8(state);
			call DiagMsg.send();
		}
		call StdControl.start();
		if( state == MCP_4x3_5x_STATE_IDLE ){
			if( !dontSleep )
				call SplitControl.stop();
		} else {
			error_t err = call Resource.request();
			if( err != SUCCESS ){
				if(call DiagMsg.record()){
					call DiagMsg.str("ponerr");
					call DiagMsg.uint8(err);
					call DiagMsg.send();
				}
				result = err;
				post signalDone();
				call SelfPower.releasePower();
				selfPowerRequested = FALSE;
			}
 		}
	}
	
	event void SelfPower.powerOff(){
		call StdControl.stop();
		if(call DiagMsg.record()){
			call DiagMsg.str("poff");
			call DiagMsg.uint8(potValueAddress);
			call DiagMsg.send();
		}
	}

	command error_t SplitControl.start(){
		error_t err = SUCCESS;
		if(call DiagMsg.record()){
			call DiagMsg.str("start");
			call DiagMsg.uint8(potValueAddress);
			call DiagMsg.uint8(power);
			call DiagMsg.uint8(selfPowerRequested);
			call DiagMsg.send();
		}
		if( power == MCP_4x3_5x_POWER_ON && selfPowerRequested )
			return EALREADY;
		if( state != MCP_4x3_5x_STATE_IDLE )
			return EBUSY;
				
		if(!selfPowerRequested){
			if(call DiagMsg.record()){
				call DiagMsg.str("start pr");
				call DiagMsg.send();
			}
			selfPowerRequested = TRUE;
			call SelfPower.requestPower();
		}
		if(call SelfPower.isPowerOn()){
			if(call DiagMsg.record()){
				call DiagMsg.str("start i2c");
				call DiagMsg.send();
			}
			err = call Resource.request();
		} else {
			err = SUCCESS;
		}
		
		if( err == SUCCESS ){
			state = MCP_4x3_5x_STATE_START;
			power = MCP_4x3_5x_POWER_ON;
		}
		return err;
	}
	
	command error_t SplitControl.stop(){
		error_t err = SUCCESS;
		if( power == MCP_4x3_5x_POWER_OFF )
			return EALREADY;
		if( state != MCP_4x3_5x_STATE_IDLE )
			return EBUSY;
		if( dontSleep )
			return FAIL;
		
		err = call Resource.request();
		if( err == SUCCESS ){
			state = MCP_4x3_5x_STATE_STOP;
			power = MCP_4x3_5x_POWER_OFF;
		}
		return err;
	}
	
	command error_t Write.write(uint16_t val){
		error_t err = SUCCESS;
		if(call DiagMsg.record()){
			call DiagMsg.str("wr");
			call DiagMsg.uint8(potValueAddress);
			call DiagMsg.uint8(state);
			call DiagMsg.uint16(val);
			call DiagMsg.send();
		}
		if( state != MCP_4x3_5x_STATE_IDLE )
			return EBUSY;
		
		err = call Resource.request();
		if( err == SUCCESS ){
			state = MCP_4x3_5x_STATE_WRITE;
			buffer[0] = val & MCP_4x3_5x_MSB_MASK;
			buffer[1] = val & MCP_4x3_5x_LSB_MASK;
			if(call DiagMsg.record()){
				call DiagMsg.str("wr ok");
				call DiagMsg.send();
			}
		} else if(call DiagMsg.record()){
				call DiagMsg.str("wr err");
				call DiagMsg.uint8(err);
				call DiagMsg.send();
			}
		return err;
	}

	command error_t Read.read(){
		error_t err = SUCCESS;
		if(call DiagMsg.record()){
			call DiagMsg.str("re");
			call DiagMsg.uint8(potValueAddress);
			call DiagMsg.uint8(state);
			call DiagMsg.send();
		}
		if( state != MCP_4x3_5x_STATE_IDLE )
			return EBUSY;
		
		err = call Resource.request();
		if( err == SUCCESS ){
			state = MCP_4x3_5x_STATE_READ;
		}
		return err;
	}

	
	event void Resource.granted()
	{
		error_t err = FAIL;
		if(call DiagMsg.record()){
			call DiagMsg.str("gr");
			call DiagMsg.uint8(potValueAddress);
			call DiagMsg.send();
		}
		switch(state){
			case MCP_4x3_5x_STATE_START://the difference is stored in the power variable
			case MCP_4x3_5x_STATE_STOP:{
				buffer[0] = (MCP_4x3_5x_TCON_ADDR << 4) | (MCP_4x3_5x_COMMAND_WRITE << 2); //general calls disabled
				buffer[1] = call MyTCONPart.getNow() | call OtherTCONPart.getNow();
				err = call Mcp4x3_5xCommunication.write(buffer, 2);
			}break;
			case MCP_4x3_5x_STATE_READ:{
				buffer[0] = (potValueAddress << 4) | (MCP_4x3_5x_COMMAND_READ << 2);
				err = call Mcp4x3_5xCommunication.write(buffer, 1);
			}break;
			case MCP_4x3_5x_STATE_WRITE:{
				buffer[0] |= (potValueAddress << 4) | (MCP_4x3_5x_COMMAND_WRITE << 2);
				err = call Mcp4x3_5xCommunication.write(buffer, 2);
			}break;
		}
		if(err != SUCCESS){
			call Resource.release();
			result = err;
			post signalDone();
		}
	}
	
	async event void Mcp4x3_5xCommunication.writeDone(error_t error, uint8_t length, void *data){
		if(call DiagMsg.record()){
			call DiagMsg.str("wd");
			call DiagMsg.uint8(potValueAddress);
			call DiagMsg.send();
		}
		if( state == MCP_4x3_5x_COMMAND_READ && error == SUCCESS ){
			error = call Mcp4x3_5xCommunication.read(buffer, 2);
		}
		if( state != MCP_4x3_5x_COMMAND_READ || error != SUCCESS){ //error could be overwritten in the previous lines, so this isn't an else
			call Resource.release();
			result = error;
			post signalDone();
		}
	}

	async event void Mcp4x3_5xCommunication.readDone(error_t error, uint8_t length, void *data){
		if(call DiagMsg.record()){
			call DiagMsg.str("rd");
			call DiagMsg.uint8(potValueAddress);
			call DiagMsg.send();
		}
		call Resource.release();
		result = error;
		post signalDone();
	}
	
	task void signalDone(){
		uint8_t prevState = state;
		state = MCP_4x3_5x_STATE_IDLE;
		if(call DiagMsg.record()){
			call DiagMsg.str("sig");
			call DiagMsg.uint8(potValueAddress);
			call DiagMsg.uint8(prevState);
			call DiagMsg.hex8s(buffer,2);
			call DiagMsg.uint8(result);
			call DiagMsg.send();
		}
		switch(prevState){
			case MCP_4x3_5x_STATE_START:{
				if(selfPowerRequested)
					signal SplitControl.startDone(result);
			}break;
			case MCP_4x3_5x_STATE_STOP:{
				if(selfPowerRequested)
					call SelfPower.releasePower();
				selfPowerRequested = FALSE;
				signal SplitControl.stopDone(result);
			}break;
			case MCP_4x3_5x_STATE_READ:{
				uint16_t value = *((nx_uint16_t*)buffer);
				value &= (MCP_4x3_5x_MSB_MASK | MCP_4x3_5x_LSB_MASK);
				signal Read.readDone(result, value);
			}break;
			case MCP_4x3_5x_STATE_WRITE:{
				uint16_t value = *((nx_uint16_t*)buffer);
				value &= (MCP_4x3_5x_MSB_MASK | MCP_4x3_5x_LSB_MASK);
				signal Write.writeDone(result, value);
			}break;
		}
	}
	
	default command error_t StdControl.start(){return SUCCESS;};
	default command error_t StdControl.stop(){return SUCCESS;};
	default event void SplitControl.startDone(error_t res){};
	default event void SplitControl.stopDone(error_t res){};
	default event void Write.writeDone(error_t success, uint16_t val) {};
	default event void Read.readDone(error_t success, uint16_t val) {};
}