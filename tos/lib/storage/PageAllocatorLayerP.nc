generic module PageAllocatorLayerP(){
  uses interface PageLayer;
  provides interface PageAllocator;
  provides interface Set<uint32_t> as PageAllocatorInit;
  uses interface DiagMsg;
}
implementation{
  enum{
    S_UNINIT,
    S_IDLE,
    S_WRITE,
    S_WRITE_LOST,
    S_READ,
    S_ERASE,
    S_ERASE_OFF
  };
  
  error_t lastError;
  uint32_t lastPage;
  void *tempBuffer;
  uint8_t state = S_UNINIT;
  
  command void PageAllocatorInit.set(uint32_t newLastPage){//TODO this might should be error checked...
    if(state == S_IDLE || state == S_UNINIT){
      lastPage = newLastPage;
      state = S_IDLE;
    }
  }
  
  command error_t PageAllocator.writeNext(void *buffer){
    if(state == S_UNINIT)
      return EOFF;
    if(state == S_WRITE)
      return EALREADY;
    if(state != S_IDLE)
      return EBUSY;
    
    if(call DiagMsg.record()){
      call DiagMsg.str("PA wr");
      call DiagMsg.uint32(lastPage);
      call DiagMsg.send();
    }
    state = S_WRITE;
    lastPage++;
    if( lastPage >= call PageLayer.getNumPages() ){
      lastPage = 0;
    }
    if( lastPage % (call PageLayer.getSectorSize() / call PageLayer.getPageSize()) == 0 ){ //first page of a sector
      if(call DiagMsg.record()){
        call DiagMsg.str("PA wr er");
        call DiagMsg.uint32(lastPage);
        call DiagMsg.uint32((lastPage / (call PageLayer.getSectorSize() / call PageLayer.getPageSize())));
        call DiagMsg.send();
      }
      state = S_WRITE_LOST;
      tempBuffer = buffer;
      lastError = call PageLayer.erase((lastPage / (call PageLayer.getSectorSize() / call PageLayer.getPageSize())), FALSE);
    } else {
      lastError = call PageLayer.write(lastPage, buffer);
    }
    return lastError;
  }
  
 
  event void PageLayer.writeDone(uint32_t pageNum, void *buffer, error_t error){
    uint8_t prevState = state;
    state = S_IDLE;
    if( prevState == S_WRITE_LOST ){ //this is the first page of a sector, we lost an old sector
      signal PageAllocator.writeNextDone(lastPage, tempBuffer, call PageLayer.getSectorSize(), ecombine(error, lastError));
    } else {
      signal PageAllocator.writeNextDone(lastPage, tempBuffer, 0, ecombine(error, lastError));
    }
  }

  
  command error_t PageAllocator.eraseAll(bool realErase){
    if(state == S_ERASE)
      return EALREADY;
    if(state != S_IDLE && state != S_UNINIT)
      return EBUSY;
    if(call DiagMsg.record()){
      call DiagMsg.str("PA er");
      call DiagMsg.uint8(realErase);
      call DiagMsg.send();
    }
    if( state == S_IDLE )
      state =S_ERASE;
    else
      state =S_ERASE_OFF;
    lastError = call PageLayer.erase(0, realErase);
    return lastError;
  }
  
  event void PageLayer.eraseDone(uint32_t sectorNum, bool realErase, error_t error){
    lastError = ecombine(lastError, error);
    if(state == S_ERASE || state == S_ERASE_OFF){
      if(call DiagMsg.record()){
        call DiagMsg.str("PA er erDone");
        call DiagMsg.uint32(sectorNum);
        call DiagMsg.uint32(error);
        call DiagMsg.send();
      }
      if(sectorNum + 1 == call PageLayer.getNumSectors()){
        if( state == S_ERASE )
          state = S_IDLE;
        else 
          state = S_UNINIT;
        lastPage = call PageLayer.getNumPages() - 1;
        signal PageAllocator.eraseDone(realErase, lastError);
        return;
      }
      if( lastError == SUCCESS )
        lastError = call PageLayer.erase(sectorNum + 1, realErase);
      if( lastError != SUCCESS ){
        if( state == S_ERASE )
          state = S_IDLE;
        else 
          state = S_UNINIT;
        signal PageAllocator.eraseDone(realErase, lastError);
      }
    } else { // state == S_WRITE_LOST
      if(call DiagMsg.record()){
        call DiagMsg.str("PA wr erDone");
        call DiagMsg.uint32(sectorNum);
        call DiagMsg.uint8(error);
        call DiagMsg.send();
      }
      if( lastError == SUCCESS )
        lastError = call PageLayer.write(lastPage, tempBuffer);
      else {
        state = S_IDLE;
        signal PageAllocator.writeNextDone(lastPage, tempBuffer, call PageLayer.getSectorSize(), error);
      }
    }
  }
  
  command error_t PageAllocator.read(uint32_t pageNum, void *buffer){
    return call PageLayer.read(pageNum, buffer);
  }
  
  event void PageLayer.readDone(uint32_t pageNum, void *buffer, error_t error){
    state = S_IDLE;
    signal PageAllocator.readDone(pageNum, buffer, error);
  }
  
  command uint16_t PageAllocator.getPageSize(){
    return call PageLayer.getPageSize();
  }
  
  command uint8_t PageAllocator.getPageSizeLog2(){
    return call PageLayer.getPageSizeLog2();
  }
  
  command uint32_t PageAllocator.getSectorSize(){
    return call PageLayer.getSectorSize();
  }
  
  command uint8_t PageAllocator.getSectorSizeLog2(){
    return call PageLayer.getSectorSizeLog2();
  }
  
  command uint32_t PageAllocator.getNumPages(){
    return call PageLayer.getNumPages();
  }
  
  command uint32_t PageAllocator.getNumSectors(){
    return call PageLayer.getNumSectors();
  }
}