generic module PageBufferLayerP(uint8_t size){
	uses interface PageAllocator;
	provides interface PageBuffer;
	provides interface Init;
	uses interface DiagMsg;
}
implementation{
	enum{
		PAGE_NOT_AVAILABLE = 0xffff,
		PAGE_INVALID = 0xffffffff,
		PAGE_VALID = 0xfffffffe,
	};
	
	typedef struct buffer_record_t{
		uint8_t lastAccessed;
		uint32_t pageNum;
		uint8_t data[PAGE_SIZE];
	} buffer_record_t;
	
	buffer_record_t* readBuffer = NULL;
	bool writeBufferLocked = FALSE;
	
	buffer_record_t readBuffers[size];
	uint8_t writeBuffer[PAGE_SIZE];
	
	uint8_t accesCounter=0;
	
	command void PageBuffer.invalidate(uint32_t fromPage, uint32_t toPage){
		uint8_t i;
		for(i=0;i<size;i++){
			if( readBuffers[i].pageNum >= fromPage && readBuffers[i].pageNum <= toPage ){
				readBuffers[i].pageNum = PAGE_INVALID;
			}
		}
	}
	
	command error_t Init.init(){
		call PageBuffer.invalidate(0, call PageAllocator.getNumPages());
		return SUCCESS;
	}
	
	inline uint16_t getPageBuffer(uint32_t pageNum){
		uint8_t i;
		for(i=0;i<size;i++){
			if( readBuffers[i].pageNum <= PAGE_VALID && readBuffers[i].pageNum == pageNum ){
				return i;
			}
		}
		return PAGE_NOT_AVAILABLE;
	}
	
	inline uint8_t getOldestBuffer(){
		uint8_t i, oldest=0, oldage=0;
		for(i=0;i<size;i++){
			if( readBuffers[i].pageNum == PAGE_INVALID ){
				return i;
			} else 
			{
				uint8_t currentage = (uint8_t)(accesCounter - readBuffers[i].lastAccessed);
				if( currentage > oldage ){
					oldage = currentage;
					oldest = i;
				}
			}
		}
		return oldest;
	}
	
	inline void readToBufferDone(error_t error){
		if( error == SUCCESS){
			readBuffer->lastAccessed = ++accesCounter;
			signal PageBuffer.readDone(readBuffer->pageNum, readBuffer->data, error);
		} else {
			signal PageBuffer.readDone(0, NULL, error);
		}
	}
	
	task void readToBufferDoneTask(){
		readToBufferDone(SUCCESS);
	}
	
	command error_t PageBuffer.readToBuffer(uint32_t pageNum){
		uint16_t bufferNum;
//     if(call DiagMsg.record()){
//       call DiagMsg.str("buffer read");
//       call DiagMsg.uint32(pageNum);
//       call DiagMsg.send();
//     }
		
		if( readBuffer != NULL )
			return EBUSY;
		
		if( pageNum >= call PageAllocator.getNumPages() )
			return EINVAL;
		
		bufferNum = getPageBuffer(pageNum);
		if( bufferNum != PAGE_NOT_AVAILABLE ){
			readBuffer = &(readBuffers[bufferNum]);
			if(call DiagMsg.record()){
				call DiagMsg.str("buffer found");
				call DiagMsg.uint32(pageNum);
				call DiagMsg.uint16((uint16_t)(readBuffer->data));
				call DiagMsg.send();
			}
			post readToBufferDoneTask();
			return SUCCESS;
		}
		
		bufferNum = getOldestBuffer();
		if(call DiagMsg.record()){
			call DiagMsg.str("buffer rewrite");
			call DiagMsg.uint32(pageNum);
			call DiagMsg.uint32(bufferNum);
			call DiagMsg.uint16((uint16_t)(readBuffer->data));
			call DiagMsg.send();
		}
		readBuffer = &(readBuffers[bufferNum]);
		return call PageAllocator.read(pageNum, readBuffer->data);
	}
	
	event void PageAllocator.readDone(uint32_t pageNum, void *buffer, error_t error){
		if(call DiagMsg.record()){
			call DiagMsg.str("buffer readDone");
			call DiagMsg.uint32(pageNum);
			call DiagMsg.uint16((uint16_t)(buffer));
			call DiagMsg.uint8(error);
			call DiagMsg.send();
		}
		if( error != SUCCESS ){
			readBuffer->lastAccessed = accesCounter + 1; //the buffer is probably messed up. set it to the oldest
			readBuffer->pageNum = PAGE_INVALID; //and set the page to invalid
			readBuffer = NULL;
		} else {
			readBuffer->pageNum = pageNum;
		}
		readToBufferDone(error);
	}
	
	command void PageBuffer.releaseReadBuffer(){
		readBuffer = NULL;
		if(call DiagMsg.record()){
			call DiagMsg.str("buffer released");
			call DiagMsg.send();
		}
	}
	
	command void* PageBuffer.getWriteBuffer(){
		if(call DiagMsg.record()){
			call DiagMsg.str("buffer wr req");
			call DiagMsg.uint8(writeBufferLocked);
			call DiagMsg.send();
		}
		if(writeBufferLocked)
			return NULL;
		
		writeBufferLocked = TRUE;
		return writeBuffer;
	}
	
	command error_t PageBuffer.flushWriteBuffer(){
		if(call DiagMsg.record()){
			call DiagMsg.str("buffer wr flush");
			call DiagMsg.uint8(writeBufferLocked);
			call DiagMsg.send();
		}
		if(!writeBufferLocked)
			return ERESERVE;
		return call PageAllocator.writeNext(writeBuffer);
	}
	
	event void PageAllocator.writeNextDone(uint32_t pageNum, void *buffer, uint32_t lostSectors, error_t error){
		if(call DiagMsg.record()){
			call DiagMsg.str("buffer wr done");
			call DiagMsg.uint8(error);
			call DiagMsg.uint32(pageNum);
			call DiagMsg.uint32(lostSectors);
			call DiagMsg.send();
		}
		signal PageBuffer.flushWriteBufferDone(pageNum, lostSectors, error);
	}
	
	command void PageBuffer.releaseWriteBuffer(){
		writeBufferLocked = FALSE;
	}
	
	command error_t PageBuffer.eraseAll(bool realErase){
		if(call DiagMsg.record()){
			call DiagMsg.str("buffer er");
			call DiagMsg.uint8(realErase);
			call DiagMsg.send();
		}
		call PageBuffer.invalidate(0, call PageBuffer.getNumPages());
		return call PageAllocator.eraseAll(realErase);
	}
	
	event void PageAllocator.eraseDone(bool realErase, error_t error){
		if(call DiagMsg.record()){
			call DiagMsg.str("buffer erDone");
			call DiagMsg.uint8(realErase);
			call DiagMsg.uint8(error);
			call DiagMsg.send();
		}
		signal PageBuffer.eraseDone(realErase, error);
	}
	
	command uint16_t PageBuffer.getPageSize(){
		return call PageAllocator.getPageSize();
	}
	
	command uint8_t PageBuffer.getPageSizeLog2(){
		return call PageAllocator.getPageSizeLog2();
	}
	
	command uint32_t PageBuffer.getSectorSize(){
		return call PageAllocator.getSectorSize();
	}
	
	command uint8_t PageBuffer.getSectorSizeLog2(){
		return call PageAllocator.getSectorSizeLog2();
	}
	
	command uint32_t PageBuffer.getNumPages(){
		return call PageAllocator.getNumPages();
	}
	
	command uint32_t PageBuffer.getNumSectors(){
		return call PageAllocator.getNumSectors();
	}
}
