generic module Mcp4x3_5xCommunicationSpiP(){
	provides interface Mcp4x3_5xCommunication;
	uses interface SpiPacket;
	uses interface GeneralIO as CS;
	provides interface StdControl;
}
implementation{
	enum{
		S_IDLE,
		S_READ,
		S_WRITE,
	};
	
	norace uint8_t state = S_IDLE;
	
	command error_t StdControl.start(){
		call CS.makeOutput();
		call CS.set();
		return SUCCESS;
	}
	
	command error_t StdControl.stop(){
		call CS.makeInput();
		call CS.clr();
		return SUCCESS;
	}
	
	async command error_t Mcp4x3_5xCommunication.write(void* buffer, uint8_t length){
		error_t err;
		if( state == S_WRITE )
			return EALREADY;
		if( state != S_IDLE )
			return EBUSY;
		state = S_WRITE;
		call CS.clr();
		err = call SpiPacket.send( buffer, NULL, length );
		if( err != SUCCESS ){
			call CS.set();
			state = S_IDLE;
		}
		return err;
	}
	
	async command error_t Mcp4x3_5xCommunication.read(void* buffer, uint8_t length){
		error_t err;
		if( state == S_READ )
			return EALREADY;
		if( state != S_IDLE )
			return EBUSY;
		state = S_READ;
		call CS.clr();
		err = call SpiPacket.send( NULL, buffer, length );
		if( err != SUCCESS ){
			call CS.set();
			state = S_IDLE;
		}
		return err;
	}
	
	async event void SpiPacket.sendDone( uint8_t* txBuf, uint8_t* rxBuf, uint16_t len, error_t error ){
		uint8_t prevState = state;
		call CS.set();
		state = S_IDLE;
		if( prevState == S_WRITE ){
			signal Mcp4x3_5xCommunication.writeDone(error, len, txBuf);
		} else {
			signal Mcp4x3_5xCommunication.readDone(error, len, rxBuf);
		}
	}
}
