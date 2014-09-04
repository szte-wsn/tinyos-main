#include "TranslationLookasideBuffer.h"
generic module AddressTranslatorLayerP(bool circular){
	uses interface TranslationLookasideBuffer as TLB;
	uses interface PageMeta;
	provides interface TranslatedStorage;
	provides interface AddressTranslatorInit;
	uses interface DiagMsg;
}
implementation{

	minmax_tlb_t minAddress, maxAddress, searchMin, searchMax;
	uint32_t readAddress;
	uint16_t writeOffsetInBuffer;
	void* writeBuffer=NULL;
	uint32_t lostBytes;
	
	//these variables used for both read and write
	uint32_t offset;
	void* buffer;
	uint32_t length;
	
	bool on = FALSE;
	
	enum{
		S_IDLE,
		S_READ,
		S_GETMIN,
		S_WRITE,
		S_SYNC,
		S_ERASE,
	};
	
	uint8_t state = S_IDLE;
	
	task void turnOn(){
		on = TRUE;
	}
	
	command void AddressTranslatorInit.init(uint32_t minAddressPage, uint32_t maxAddressPage, uint32_t maxStartAddress, uint16_t maxFilledByte){
		if(call DiagMsg.record()){
			call DiagMsg.str("TR strt");
			call DiagMsg.uint32(minAddressPage);
			call DiagMsg.uint32(maxAddressPage);
			call DiagMsg.uint32(maxStartAddress);
			call DiagMsg.uint16(maxFilledByte);
			call DiagMsg.send();
		}
		minAddress.valid = FALSE;
		minAddress.page = minAddressPage;
		
		maxAddress.page = maxAddressPage;
		maxAddress.address = maxStartAddress;
		maxAddress.bytesFilled = maxFilledByte;
		if(maxAddress.bytesFilled == 0) 
			maxAddress.valid = FALSE; //flash is empty. We're invalid, until someone starts writing
		else
			maxAddress.valid = TRUE;
		post turnOn();
	}
	
	void iterate(){
		error_t err = SUCCESS;
		uint32_t readPage;
		if( !searchMin.valid ){
			readPage = searchMin.page;
			call PageMeta.readMeta(readPage);
		} else if( readAddress >= searchMin.address && readAddress < searchMin.address + searchMin.bytesFilled ){ // on min page
			readPage = searchMin.page;
			call PageMeta.readPage(readPage);
		} else if( readAddress >= searchMax.address && readAddress < searchMax.address + searchMax.bytesFilled ){ // on min page
			readPage = searchMax.page;
			call PageMeta.readPage(readPage);
		} else { // not on these pages
			//assume the data density is linear on the drive (which is not, that's why we iterate)
			int64_t pages;
			if( searchMax.page > searchMin.page )
				pages = (int64_t)searchMax.page - searchMin.page;
			else
				pages = (int64_t)searchMax.page +  (call PageMeta.getNumPages() - searchMin.page);
			readPage = (uint32_t)(searchMin.page + (( pages * (readAddress - searchMin.address)) / (searchMax.address - searchMin.address))) % (call PageMeta.getNumPages());
			
			if(call DiagMsg.record()){
				call DiagMsg.str("TR it");
				call DiagMsg.uint32(readAddress);
				call DiagMsg.uint32(searchMin.page);
				call DiagMsg.uint32(searchMin.address);
				call DiagMsg.uint16(searchMin.bytesFilled);
				call DiagMsg.uint8(searchMin.valid);
				call DiagMsg.send();
			}
			if(call DiagMsg.record()){;
				call DiagMsg.uint32(searchMax.page);
				call DiagMsg.uint32(searchMax.address);
				call DiagMsg.uint16(searchMax.bytesFilled);
				call DiagMsg.uint8(searchMax.valid);
				call DiagMsg.uint32(readPage);
				call DiagMsg.uint8(err);
				call DiagMsg.send();
			}
			
			if( (readPage <= searchMin.page) && ((searchMin.page < searchMax.page) || ((searchMin.page > searchMax.page) && (readPage > searchMax.page))) ){
				readPage = searchMin.page + 1;
			} else if( (readPage >= searchMax.page) && ((searchMin.page < searchMax.page) || ((searchMin.page > searchMax.page) && (readPage < searchMin.page))) ){
				readPage = searchMax.page -1;
			}
			err = call PageMeta.readMeta(readPage);
		} 
	}
	
	event void PageMeta.readMetaDone(uint32_t pageNum, void *readBuffer, error_t error){
		if(on){
			if(call DiagMsg.record()){
				call DiagMsg.str("translator rmd");
				call DiagMsg.uint32(pageNum);
				call DiagMsg.uint8(state);
				call DiagMsg.send();
			}
			if( error == SUCCESS ){
				metadata_t* meta = (metadata_t*)readBuffer;
				if( pageNum == minAddress.page ){
					minAddress.address = searchMin.address = meta->startAddress;
					minAddress.valid = searchMin.valid = TRUE;
					minAddress.bytesFilled = searchMin.bytesFilled = meta->filledBytes;
				} else { //state == S_READ
					call TLB.addNew(meta->startAddress, pageNum, meta->filledBytes);//we store the min address locally, so we don't want it to be in the TLB
					if( meta->startAddress <= readAddress ){
						searchMin.page = pageNum;
						searchMin.address = meta->startAddress;
						searchMin.valid = TRUE;
						searchMin.bytesFilled = meta->filledBytes;
					} else {
						searchMax.page = pageNum;
						searchMax.address = meta->startAddress;
						searchMax.valid = TRUE;
						searchMax.bytesFilled = meta->filledBytes;
					}
				}
				call PageMeta.releaseReadBuffer();
				if( state == S_GETMIN ){
					state = S_IDLE;
					signal TranslatedStorage.getMinAddressDone(SUCCESS, minAddress.address);
				} else { // state == S_READ
					iterate();
				}
			} else {
				uint8_t prevState = state;
				state = S_IDLE;
				if( prevState == S_GETMIN )
					signal TranslatedStorage.getMinAddressDone(error, 0xffffffff);
				else // state == S_READ
					signal TranslatedStorage.readDone(error, readAddress, length, buffer);
			}
		}
	}
	
	event void PageMeta.readPageDone(uint32_t pageNum, void *readBuffer, uint32_t startAddress, uint16_t filledBytes, error_t error){
		if(on){
			if( error == SUCCESS ){
				if(call DiagMsg.record()){
					call DiagMsg.str("TR rDone");
					call DiagMsg.uint32(pageNum);
					call DiagMsg.uint32(startAddress);
					call DiagMsg.uint32(readAddress);
					call DiagMsg.uint32(offset);
					call DiagMsg.send();
				}
				if(call DiagMsg.record()){
					call DiagMsg.uint32(length);
					call DiagMsg.uint16(filledBytes);
					call DiagMsg.uint32(maxAddress.page);
					call DiagMsg.send();
				}
				//we could add this page to the tlb now, but it's probably not the best idea: it can easily fill all the buffers with sequential pages
				if( readAddress + offset != startAddress ){
					if( offset == 0 && (readAddress - startAddress) <= filledBytes ){ //first page, and we don't need the first part
						uint16_t readLength;
						readLength = filledBytes - (readAddress - startAddress);
						if( length < readLength )
							readLength = length;
						memcpy((void*)(buffer), (void*)(readBuffer + (readAddress - startAddress)), readLength);
						call PageMeta.releaseReadBuffer();
						offset += readLength;
						if( offset != length ){
							if( maxAddress.page == pageNum ){ //read the rest from the write buffer
								memcpy((void*)(buffer + offset), writeBuffer, length - offset);
								offset = length;
							} else 
								call PageMeta.readPage((pageNum + 1) % (call PageMeta.getNumPages()));
						}
					} else { //something is totally wrong: eighter we thought that we found the first page, but we didn't, or the addressing is not strictly increasing
						//TODO this is a serious error, give some better error, at least in diag
						state = S_IDLE;
						call PageMeta.releaseReadBuffer();
						signal TranslatedStorage.readDone(FAIL, readAddress, length, buffer);
					}
				} else if( offset + filledBytes < length ){
					memcpy((void*)(buffer + offset), readBuffer, filledBytes);
					call PageMeta.releaseReadBuffer();
					offset += filledBytes;
					if( maxAddress.page == pageNum ){ //read the rest from the write buffer
						memcpy((void*)(buffer + offset), writeBuffer, length - offset);
						offset = length;
					} else 
						call PageMeta.readPage((pageNum + 1) % (call PageMeta.getNumPages()));
				} else { //last page
					memcpy((void*)(buffer + offset), readBuffer, length - offset);
					offset = length;
					call PageMeta.releaseReadBuffer();
				}
			} else {
				call PageMeta.releaseReadBuffer();
				state = S_IDLE;
				signal TranslatedStorage.readDone(error, readAddress, length, buffer);
			}
			if( offset == length ){
				call TLB.addNew(startAddress, pageNum, filledBytes);
				state = S_IDLE;
				signal TranslatedStorage.readDone(SUCCESS, readAddress, length, buffer);
			}
		}
	}
	
	task void readDone(){
		state = S_IDLE;
		signal TranslatedStorage.readDone(SUCCESS, readAddress, length, buffer);
	}
	
	command error_t TranslatedStorage.read(uint32_t address, uint32_t len, void* data){
		if(call DiagMsg.record()){
			call DiagMsg.str("TR rd");
			call DiagMsg.uint32(address);
			call DiagMsg.uint32(len);
			call DiagMsg.uint8(state);
			call DiagMsg.send();
		}
		if( state == S_READ )
			return EALREADY;
		if( state != S_IDLE )
			return EBUSY;
		if( !maxAddress.valid && writeBuffer == NULL )
			return EOFF;
		if( minAddress.valid && address < minAddress.address )
			return EINVAL;
		if( maxAddress.valid && (call TranslatedStorage.getMaxAddress() + 1 < address + len ))
			return EINVAL;
		if( !maxAddress.valid && writeOffsetInBuffer < address + len )
			return EINVAL;
		
		state = S_READ;
		
		readAddress = address;
		length = len;
		buffer = data;
		
		if( !maxAddress.valid || call PageMeta.getLastAddress() < readAddress ){ //read from write buffer only
			offset = readAddress;
			if( maxAddress.valid )
				offset = readAddress - (call PageMeta.getLastAddress() + 1);
			if(call DiagMsg.record()){
				call DiagMsg.uint32(offset);
				call DiagMsg.uint32(readAddress);
				call DiagMsg.send();
			}
			memcpy(buffer, (void*)(writeBuffer + offset), length);
			post readDone();
			return SUCCESS;
		}
		
		offset = 0;
		searchMin = minAddress;
		searchMax = maxAddress;
		
		call TLB.getClosest(&searchMin, &searchMax, readAddress);
		iterate();
		return SUCCESS;
	}
	
	task void getMinAddressDone(){
		state = S_IDLE;
		signal TranslatedStorage.getMinAddressDone(SUCCESS, minAddress.address);
	}
	
	command error_t TranslatedStorage.getMinAddress(){
		if(call DiagMsg.record()){
			call DiagMsg.str("translator gm");
			call DiagMsg.uint8(minAddress.valid);
			call DiagMsg.uint32(minAddress.page);
			call DiagMsg.uint32(minAddress.address);
			call DiagMsg.uint8(maxAddress.valid);
			call DiagMsg.uint8(state);
			call DiagMsg.send();
		}
		if( state == S_GETMIN )
			return EALREADY;
		if( state != S_IDLE )
			return EBUSY;
		if( !maxAddress.valid && writeBuffer == NULL )
			return EOFF;
		
		state = S_GETMIN;
		if(minAddress.valid || !maxAddress.valid) //if the maxAddress is invalid, the flash is empty, minAddress is 0
			post getMinAddressDone();
		else if(maxAddress.valid)
			call PageMeta.readMeta(minAddress.page);
		return SUCCESS;
	}
	
	task void writeDone(){
		state = S_IDLE;
		signal TranslatedStorage.writeDone(SUCCESS, maxAddress.address + writeOffsetInBuffer - length, length, 0, buffer);
	}
	
	command error_t TranslatedStorage.write(void* data, uint32_t len){
		if( state == S_WRITE )
			return EALREADY;
		if( state != S_IDLE )
			return EBUSY;
		if( !circular && maxAddress.valid && 
				(maxAddress.page >= call PageMeta.getNumPages() || //full
				(maxAddress.page + 1 == call PageMeta.getNumPages() && writeOffsetInBuffer + length >= call PageMeta.getPageSize()) //will be full
				)
			)
			return EINVAL;
		
		state = S_WRITE;
		
		if(call DiagMsg.record()){
			call DiagMsg.str("translator wr");
			call DiagMsg.uint32(maxAddress.page);
			call DiagMsg.uint32(len);
			call DiagMsg.uint32(writeOffsetInBuffer);
			call DiagMsg.send();
		};
		
		offset = 0;
		lostBytes = 0;
		buffer = data;
		length = len;
		
		if( writeBuffer == NULL ){
			writeBuffer = call PageMeta.getWriteBuffer();
			writeOffsetInBuffer = 0;
			if( writeBuffer == NULL )
				return FAIL;
		}
		
		if( writeOffsetInBuffer + length < call PageMeta.getPageSize() ){ //new data goes to buffer
			memcpy((void*)(writeBuffer + writeOffsetInBuffer), buffer, length);
			writeOffsetInBuffer += length;
			post writeDone();
		} else { //some new data goes to buffer, then ask for new
			memcpy((void*)(writeBuffer + writeOffsetInBuffer), buffer, call PageMeta.getPageSize() - writeOffsetInBuffer );
			return call PageMeta.flushWriteBuffer(call PageMeta.getPageSize());
		}
		return SUCCESS;
	}
	
	event void PageMeta.flushWriteBufferDone(uint32_t pageNum, uint32_t startAddress, uint16_t filledBytes, uint32_t lostData, error_t error){
		if(on){
			if(call DiagMsg.record()){
				call DiagMsg.str("tr wr fdone");
				call DiagMsg.uint32(pageNum);
				call DiagMsg.uint32(startAddress);
				call DiagMsg.uint32(length);
				call DiagMsg.send();
			}
			if(call DiagMsg.record()){
				call DiagMsg.uint32(offset);
				call DiagMsg.uint8(error);
				call DiagMsg.uint32(lostData);
				call DiagMsg.uint32(lostBytes);
				call DiagMsg.uint8(state);
				call DiagMsg.uint32(minAddress.page);
				call DiagMsg.send();
			}
			if( error == SUCCESS ){
				if( maxAddress.valid && lostData>0 && pageNum == minAddress.page ){//maxAddress was invalid, if the flash is empty
					uint32_t newMinPage = minAddress.page + call PageMeta.getSectorSize() / call PageMeta.getPageSize();
					minAddress.valid = FALSE;
					call TLB.invalid(minAddress.page, newMinPage - 1);
					minAddress.page += call PageMeta.getSectorSize() / call PageMeta.getPageSize();
					lostBytes += call PageMeta.getSectorSize();
				}
				maxAddress.page = pageNum;
				maxAddress.address = startAddress;
				maxAddress.bytesFilled = filledBytes;
				maxAddress.valid = TRUE;
				if( state == S_WRITE ){
					offset += filledBytes - writeOffsetInBuffer;
					writeOffsetInBuffer = 0;
					if( length - offset < call PageMeta.getPageSize() ){ //that was the last flash write
						if( length - offset != 0 ){ //new data goes to buffer, then done
							memcpy(writeBuffer, (void*)(buffer + offset), length - offset);
							writeOffsetInBuffer += length - offset;   
							offset = length;
						}
						
						state = S_IDLE;
						signal TranslatedStorage.writeDone(SUCCESS, call TranslatedStorage.getMaxAddress() - length, length, lostBytes, buffer);
					} else { //some new data goes to buffer, then ask for new
						error_t err = SUCCESS;
						memcpy(writeBuffer, (void*)(buffer + offset), call PageMeta.getPageSize());
						err = call PageMeta.flushWriteBuffer(call PageMeta.getPageSize());
						if( err!= SUCCESS){
							state = S_IDLE;
							signal TranslatedStorage.writeDone(error, 0, length, 0, buffer);
						}
					}
					
				} else { //S_SYNC
					state = S_IDLE;
					writeOffsetInBuffer = 0;
					signal TranslatedStorage.syncDone(SUCCESS, lostBytes);
				}
			} else {
				uint8_t prevState = state;
				state = S_IDLE;
				writeOffsetInBuffer = 0;
				if( prevState == S_WRITE ){
					signal TranslatedStorage.writeDone(error, 0, length, 0, buffer);
				} else { //S_SYNC
					signal TranslatedStorage.syncDone(error, lostBytes);
				}
			}
		}
	}
	
	task void syncDone(){
		state = S_IDLE;
		signal TranslatedStorage.syncDone(SUCCESS, 0);
	}
	
	command error_t TranslatedStorage.sync(){
		if( state == S_SYNC )
			return EALREADY;
		if( state != S_IDLE )
			return EBUSY;

		state = S_SYNC;
		
		if( writeOffsetInBuffer == 0 ){
			post syncDone();
			return SUCCESS;
		} else {
			lostBytes = 0;
			return call PageMeta.flushWriteBuffer(writeOffsetInBuffer);
		}
	}
	
	command uint32_t TranslatedStorage.getMaxAddress(){
		return call PageMeta.getLastAddress()+writeOffsetInBuffer;
	}
	
	command error_t TranslatedStorage.eraseAll(){
		if( state == S_ERASE )
			return EALREADY;
		if( state != S_IDLE )
			return EBUSY;

		state = S_ERASE;
		if(call DiagMsg.record()){
			call DiagMsg.str("erase");
			call DiagMsg.send();
		}
		
		return call PageMeta.eraseAll(TRUE);//we must do a real erase, otherwise init will fail
	}
	
	event void PageMeta.eraseDone(bool realErase, error_t error){
		if( error != SUCCESS ){
			state = S_IDLE;
			signal TranslatedStorage.eraseAllDone(error);
		} else {
			call TLB.invalid(0, call PageMeta.getNumPages() - 1);
			minAddress.valid = FALSE;
			minAddress.page = 0;
			maxAddress.page = 0;
			maxAddress.address = 0;
			maxAddress.bytesFilled = 0;
			maxAddress.valid = FALSE; //flash is empty. We're invalid, until someone starts writing
			call PageMeta.releaseWriteBuffer();
			writeBuffer = NULL;
			state = S_IDLE;
			signal TranslatedStorage.eraseAllDone(error);
		}
	}
	
	default event void TranslatedStorage.getMinAddressDone(error_t error, uint32_t address){}
	default event void TranslatedStorage.readDone(error_t error, uint32_t readAddr, uint32_t len, void* buf){}
	default event void TranslatedStorage.writeDone(error_t error, uint32_t address, uint32_t len, uint32_t lostB, void* buf){}
	default event void TranslatedStorage.syncDone(error_t error, uint32_t lostB){}
	default event void TranslatedStorage.eraseAllDone(error_t error){}
}