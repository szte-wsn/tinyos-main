module StreamStorageRamP{
	provides interface StreamStorageErase;
	provides interface StreamStorageRead;
	provides interface StreamStorageWrite;
	provides interface SplitControl;
	uses interface DiagMsg;
}
implementation{
	enum{
		BUFFERSIZE=8192,
	};
	
	enum{
		S_OFF,
		S_IDLE,
		S_APP_ID,
		S_APP,
		S_SYNC,
		S_RD,
		S_GETMINADDR,
		S_ERASE,
		S_START,
		S_STOP,
	};
	
	bool overflow = FALSE;
	
	uint8_t state=S_OFF;
	
	uint8_t buffer[BUFFERSIZE];
	uint16_t offset = 0;
	uint32_t address=0;
	uint32_t minAddress=0;
	uint8_t lastId;
	void* lastBuffer;
	uint16_t lastLen;
	
	uint32_t readAddress;
	uint8_t readLen;
	uint8_t* readBuffer;
	
	task void process(){
		if(call DiagMsg.record()){
			call DiagMsg.uint8(state);
			call DiagMsg.uint32(address);
			call DiagMsg.uint32(offset);
			call DiagMsg.uint32(minAddress);
			call DiagMsg.send();
		}
		switch(state){
			case S_APP_ID:{
				if(offset == BUFFERSIZE){
					offset = 0;
					overflow = TRUE;
				}
				*((uint8_t*)(buffer+offset)) = lastId;
				offset++;
				address++;
				if(overflow)
					minAddress++;
			}//fall through
			case S_APP:{
				address += lastLen;
				if(offset == BUFFERSIZE){
					offset = 0;
					overflow = TRUE;
				}
				if(overflow)
					minAddress+=lastLen;
				if( offset + lastLen > BUFFERSIZE ){
					memcpy((uint8_t*)(buffer+offset), (uint8_t*)lastBuffer, BUFFERSIZE - offset);
					lastLen -= (BUFFERSIZE - offset);
					offset = 0;
					if(!overflow){
						minAddress += lastLen;
						overflow = TRUE;
					}
				}
				
				memcpy((uint8_t*)(buffer+offset), (uint8_t*)lastBuffer, lastLen);
				offset += lastLen;
				if(state == S_APP_ID){
					state = S_IDLE;
					signal StreamStorageWrite.appendDoneWithID(lastBuffer, lastLen, SUCCESS);
				} else {
					state = S_IDLE;
					signal StreamStorageWrite.appendDone(lastBuffer, lastLen, SUCCESS);
				}
			}break;
			case S_SYNC:{
				state = S_IDLE;
				signal StreamStorageWrite.syncDone(SUCCESS);
			}break;
			case S_RD:{
				uint32_t rdOffset = readAddress%BUFFERSIZE;
				uint8_t rdLen = lastLen;
				uint8_t rdBufferOffset = 0;
				if(rdOffset + rdLen > BUFFERSIZE){
					memcpy(lastBuffer, (uint8_t*)(buffer + rdOffset), BUFFERSIZE - rdOffset);
					rdBufferOffset = BUFFERSIZE - rdOffset;
					rdLen -= rdBufferOffset;
				}
				memcpy(lastBuffer + rdBufferOffset, (uint8_t*)(buffer + rdOffset), rdLen);
				state = S_IDLE;
				signal StreamStorageRead.readDone(lastBuffer, lastLen, SUCCESS);
			}break;
			case S_GETMINADDR:{
				state = S_IDLE;
				signal StreamStorageRead.getMinAddressDone(minAddress, SUCCESS);
			}break;
			case S_ERASE:{
				minAddress = 0;
				address = 0;
				offset = 0;
				overflow = FALSE;
				state = S_IDLE;
				signal StreamStorageErase.eraseDone(SUCCESS);
			}break;
			case S_START:{
				minAddress = 0;
				address = 0;
				offset = 0;
				overflow = FALSE;
				state = S_IDLE;
				signal SplitControl.startDone(SUCCESS);
			}break;
			case S_STOP:{
				minAddress = 0;
				address = 0;
				offset = 0;
				overflow = FALSE;
				state = S_OFF;
				signal SplitControl.startDone(SUCCESS);
			}break;
		}
	}
	
	command error_t StreamStorageWrite.appendWithID(nx_uint8_t id, void* buf, uint16_t  len){
		if(state != S_IDLE)
			return EBUSY;
		
		lastBuffer = buf;
		lastId = id;
		lastLen = len;
		
		state = S_APP_ID;
		
		post process(); 
		return SUCCESS;
	}
	
	command error_t StreamStorageWrite.append(void* buf, uint16_t  len){
		if(state != S_IDLE)
			return EBUSY;
		
		lastBuffer = buf;
		lastLen = len;
		
		state = S_APP;
		
		post process(); 
		return SUCCESS;
	}
	
	command error_t StreamStorageWrite.sync(){
		if(state != S_IDLE)
			return EBUSY;
		
		state = S_SYNC;
		
		post process(); 
		return SUCCESS;
	}
	
	command error_t StreamStorageRead.getMinAddress(){
		if(state != S_IDLE)
			return EBUSY;
		
		state = S_GETMINADDR;
		
		post process(); 
		return SUCCESS;
	}
	
	command uint32_t StreamStorageRead.getMaxAddress(){ 
		if(address == 0)
			return address;
		else
			return address-1;
	}
	
	command error_t StreamStorageRead.read(uint32_t addr, void* buf, uint8_t  len){
		if(call DiagMsg.record()){
			call DiagMsg.str("rd");
			call DiagMsg.uint8(state);
			call DiagMsg.uint32(addr);
			call DiagMsg.uint32(addr%BUFFERSIZE);
			call DiagMsg.uint8(len);
			call DiagMsg.send();
		}
		if(state != S_IDLE)
			return EBUSY;
		if(addr < minAddress || addr> address)
			return EINVAL;
		
		lastBuffer = buf;
		lastLen = len;
		readAddress = addr;
		
		state = S_RD;
		
		post process(); 
		return SUCCESS;
	}
	
	command error_t StreamStorageErase.erase(){
		if(state != S_IDLE)
			return EBUSY;
		
		state = S_ERASE;
		
		post process(); 
		return SUCCESS;
	}
	
	command error_t SplitControl.start(){
		if(state != S_OFF)
			return EALREADY;
		
		state = S_START;
		
		post process(); 
		return SUCCESS;
	}
	
	command error_t SplitControl.stop(){
		if(state == S_OFF)
			return EALREADY;
		else if(state != S_IDLE)
			return EBUSY;
		
		state = S_START;
		
		post process(); 
		return SUCCESS;
	}
}