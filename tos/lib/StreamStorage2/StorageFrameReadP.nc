#include "StorageFrame.h"
generic module StorageFrameReadP(){
	provides interface FramedRead;
	uses interface StreamStorageRead as SubRead;
}
implementation{
	enum{
		S_SEARCH_START,
		S_READ,
		S_READ_ESCAPE,
		S_IDLE,
	};
	
	uint16_t bufferlen;
	uint16_t readylen;
	void* buffer;
	uint32_t startAddress, currentAddress;
	uint8_t state = S_IDLE;
	
	command error_t FramedRead.getMinAddress(){
		return call SubRead.getMinAddress();
	}
	
	event void SubRead.getMinAddressDone(uint32_t addr,error_t error){
		signal FramedRead.getMinAddressDone(addr, error);
	}
	
	command uint32_t FramedRead.getMaxAddress(){
		return call SubRead.getMaxAddress();
	}
	
	command error_t FramedRead.read(uint32_t addr, void* buf, uint16_t  buflen){
		error_t ret;
		if( state != S_IDLE )
			return EBUSY;
		
		state = S_SEARCH_START;
		buffer = buf;
		bufferlen = buflen;
		startAddress = addr;
		ret = call SubRead.read(addr, buf, bufferlen);
		if( ret!=SUCCESS ){
			state = S_IDLE;
		}
		return ret;
	}
	
	event void SubRead.readDone(void* buf, uint8_t len, error_t error){
		if( error != SUCCESS ){
			signal FramedRead.readDone(error, buffer, bufferlen, startAddress, readylen, currentAddress);
		} else if( state == S_SEARCH_START ){
			uint16_t i = 0;
			while( i < len && *((uint8_t*)(buf+i)) != FRAMEBYTE){
				i++;
			}
			while( i < len && *((uint8_t*)(buf+i)) == FRAMEBYTE){
				i++;
			}
			if( i==len ){ //there was no frame start byte in the buffer, or after the first frame start byte, there are only frame start bytes
				startAddress = startAddress + i - 1;//overlap with the last byte: in case of the framing was read, but no data
				error = call SubRead.read(startAddress, buffer, bufferlen);
				if( error != SUCCESS ){
					signal FramedRead.readDone(error, buffer, bufferlen, startAddress, readylen, currentAddress);
				}
			} else {
				state = S_READ;
				startAddress = startAddress + i - 1;//last frame byte
				currentAddress = startAddress + 1;
				readylen = 0;
				/*
				 * read the data with one byte at a time. This seems slow, but reading a lot of stuff at once has some major disatvantages:
				 *  - we need to copy (or re-read) everything after an escaped byte
				 *  - we probably will read more than needed
				 * while the disadvantage of reading one byte only is that we have to go through arbitration with every byte, 
				 * and the addresstranslator has to figure out that the needed byte is in the buffer.
				 */
				error = call SubRead.read(currentAddress, buffer+readylen, 1);
				if( error != SUCCESS ){
					signal FramedRead.readDone(error, buffer, bufferlen, startAddress, readylen, currentAddress);
				}
			}
		} else if( state == S_READ) {
			if( *(uint8_t*)buf == FRAMEBYTE ){ //end of frame, finish everything
				state  = S_IDLE;
				signal FramedRead.readDone(SUCCESS, buffer, bufferlen, startAddress, readylen, currentAddress);
				return;
			} else if( *(uint8_t*)buf == ESCAPEBYTE ){ //escape the next byte
				state = S_READ_ESCAPE;
			} else { //nothing fancy, just data
				readylen++;
			}
			if( readylen >= bufferlen){//frame is longer than buffer
				state = S_IDLE;
				signal FramedRead.readDone(ENOMEM, buffer, bufferlen, startAddress, readylen, currentAddress);
			} else {
				error = call SubRead.read(++currentAddress, buffer+readylen, 1);
				if( error != SUCCESS ){
					signal FramedRead.readDone(error, buffer, bufferlen, startAddress, readylen, currentAddress);
				}
			}
		} else if( state == S_READ_ESCAPE ){
			*(uint8_t*)buf ^= XORESCAPEBYTE;
			if( ++readylen >= bufferlen){//frame is longer than buffer
				state = S_IDLE;
				signal FramedRead.readDone(ENOMEM, buffer, bufferlen, startAddress, readylen, currentAddress);
			} else {
				state = S_READ;
				error = call SubRead.read(++currentAddress, buffer+readylen, 1);
				if( error != SUCCESS ){
					signal FramedRead.readDone(error, buffer, bufferlen, startAddress, readylen, currentAddress);
				} 
			}
		}
	}
}