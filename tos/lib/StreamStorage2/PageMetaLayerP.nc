#include "PageMetaLayer.h"
generic module PageMetaLayerP(){
  provides interface PageMeta;
  uses interface PageBuffer;
  provides interface Set<uint32_t> as MetaInit;
  uses interface DiagMsg;
}
implementation{
  
  typedef nx_struct page_with_meta_t{
    nx_uint8_t data[PAGE_SIZE-sizeof(metadata_t)];
    metadata_t meta;
  } page_with_meta_t;
  
  uint32_t currentAddr;
  bool on = FALSE;
  page_with_meta_t* writeBuffer;
  
  enum{
    S_IDLE,
    S_META,
    S_DATA,
  };
  
  uint8_t readState = S_IDLE;
  
  command void MetaInit.set(uint32_t newaddr){
    currentAddr = newaddr;
    on = TRUE;
  }
  
  command uint32_t PageMeta.getLastAddress(){
    return currentAddr - 1;
  }
  
  command void* PageMeta.getWriteBuffer(){
    if( !on )
      return NULL;
    
    writeBuffer = (page_with_meta_t*)call PageBuffer.getWriteBuffer();
    return writeBuffer->data;
  }
  
  command error_t PageMeta.flushWriteBuffer(uint16_t filledBytes){
    error_t err;
    if( writeBuffer == NULL )
      return ERESERVE;
    
    (writeBuffer->meta).filledBytes = filledBytes;
    (writeBuffer->meta).startAddress = currentAddr;
    err = call PageBuffer.flushWriteBuffer();
    if( err == SUCCESS )
      currentAddr += filledBytes;
    return err;
  }
  
  event void PageBuffer.flushWriteBufferDone(uint32_t pageNum, uint32_t lostSectors, error_t error){
    signal PageMeta.flushWriteBufferDone(pageNum, (writeBuffer->meta).startAddress, (writeBuffer->meta).filledBytes, lostSectors, error);
  }
  
  command void PageMeta.releaseWriteBuffer(){
    writeBuffer = NULL;
    call PageBuffer.releaseWriteBuffer();
  }
  
  command error_t PageMeta.readMeta(uint32_t pageNum){
    if( readState != S_IDLE )
      return EBUSY;
    
    readState = S_META;
    return call PageBuffer.readToBuffer(pageNum);
  }
  
  command error_t PageMeta.readPage(uint32_t pageNum){
    error_t err;
    if( readState != S_IDLE )
      return EBUSY;
    
    err = call PageBuffer.readToBuffer(pageNum);
    if( err == SUCCESS)
      readState = S_DATA;
    
    return err;
  }
   
  event void PageBuffer.readDone(uint32_t pageNum, void *buffer, error_t error){
    if(call DiagMsg.record()){
      call DiagMsg.str("meta readDone");
      call DiagMsg.uint32(pageNum);
      call DiagMsg.uint8(readState);
      call DiagMsg.uint8(error);
      call DiagMsg.send();
    }
    if( readState == S_META ){
      readState = S_IDLE;
      if( buffer != NULL ){
        page_with_meta_t* data = (page_with_meta_t*)buffer;
        signal PageMeta.readMetaDone(pageNum, &(data->meta), error);
      } else {
        call PageBuffer.releaseReadBuffer();
        signal PageMeta.readMetaDone(pageNum, NULL, error);
      }
    } else { //readState == S_DATA
      readState = S_IDLE;
      if( buffer != NULL ){
        page_with_meta_t* data = (page_with_meta_t*)buffer;
        signal PageMeta.readPageDone(pageNum, data->data, (data->meta).startAddress, (data->meta).filledBytes, error);
      } else {
        call PageBuffer.releaseReadBuffer();
        signal PageMeta.readPageDone(pageNum, NULL, 0, 0, error);
      }
    }
  }
  
  command void PageMeta.releaseReadBuffer(){
    call PageBuffer.releaseReadBuffer();
  }
  
  command error_t PageMeta.eraseAll(bool realErase){
    return call PageBuffer.eraseAll(realErase);
  }
  
  event void PageBuffer.eraseDone(bool realErase, error_t error){
    if( error == SUCCESS )
      currentAddr = 0;
    signal PageMeta.eraseDone(realErase, error);
  }
  
  command void PageMeta.invalidate(uint32_t fromPage, uint32_t toPage){
		call PageBuffer.invalidate(fromPage, toPage);
	}
  
  command uint16_t PageMeta.getPageSize(){
    return call PageBuffer.getPageSize() - sizeof(metadata_t);
  }
  
  command uint32_t PageMeta.getSectorSize(){
    return call PageBuffer.getSectorSize() - sizeof(metadata_t)*(call PageBuffer.getSectorSize()/call PageBuffer.getPageSize());
  }
  
  command uint32_t PageMeta.getNumPages(){
    return call PageBuffer.getNumPages();
  }
  
  command uint32_t PageMeta.getNumSectors(){
    return call PageBuffer.getNumSectors();
  }
}