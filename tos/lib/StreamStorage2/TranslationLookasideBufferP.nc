#include "TranslationLookasideBuffer.h"
generic module TranslationLookasideBufferP(uint8_t size){
  provides interface TranslationLookasideBuffer as TLB;
  provides interface Init;
  uses interface DiagMsg;
}
implementation{
  typedef struct tlb_entry_t{
    uint32_t address;
    uint32_t page;
    uint16_t bytesFilled;
    uint8_t age;
    bool valid;
  } tlb_entry_t;
  
  tlb_entry_t buffer[size];
  uint8_t ageCounter;
  
  inline uint8_t getOldest(uint32_t address ){
    uint8_t i, maxAge=0, maxAgeAt=0;
    bool found = FALSE;
    for(i=0;i<size;i++){
      if( buffer[i].valid && buffer[i].address == address ){
        return i;//found the same entry, exit early
      }
      if( !buffer[i].valid ){
        maxAgeAt = i;
        found = TRUE; //from now, we only check for possible buffer duplication
      } else if( !found && (((uint8_t)(ageCounter - buffer[i].age)) > maxAge) ) { //this method doesn't work, if the ageCounter overflows twice since the oldest counter was set. However, we accept this price to save memory
        maxAge = (uint8_t)(ageCounter - buffer[i].age);
        maxAgeAt = i;
      }
    }
    if( call DiagMsg.record()){
      call DiagMsg.str("TLB oldest");
      call DiagMsg.uint8(ageCounter);
      call DiagMsg.uint8(maxAge);
      call DiagMsg.uint8(maxAgeAt);
      call DiagMsg.send();
    }
    return maxAgeAt;
  }
  
  command error_t Init.init(){
    uint8_t i;
    for(i=0;i<size;i++){
      buffer[i].valid = FALSE;
    }
    return SUCCESS;
  }
  
  command void TLB.addNew(uint32_t address, uint32_t page, uint16_t filledBytes){
    uint8_t oldest = getOldest(address);
    if( call DiagMsg.record()){
      call DiagMsg.str("TLB new");
      call DiagMsg.uint32(address);
      call DiagMsg.uint32(page);
      call DiagMsg.uint16(filledBytes);
      call DiagMsg.uint32(buffer[oldest].address);
      call DiagMsg.uint32(buffer[oldest].page);
      call DiagMsg.uint16(buffer[oldest].bytesFilled);
      call DiagMsg.send();
    }
    buffer[oldest].address = address;
    buffer[oldest].page = page;
    buffer[oldest].bytesFilled = filledBytes;
    buffer[oldest].age = ++ageCounter;
		buffer[oldest].valid = TRUE;
  }
  
  command void TLB.getClosest(minmax_tlb_t *low, minmax_tlb_t *high, uint32_t searchAddress){
    uint8_t i;
    for(i=0;i<size;i++){
      if( buffer[i].valid ){
        if(buffer[i].address <= searchAddress){
          if( !(low->valid) || low->address < buffer[i].address ){
            low->address = buffer[i].address;
            low->page = buffer[i].page;
            low->bytesFilled = buffer[i].bytesFilled;
            low->valid = TRUE;
          }
        } else {
          if(!(high->valid) || high->address > buffer[i].address ){
            high->address = buffer[i].address;
            high->page = buffer[i].page;
            high->bytesFilled = buffer[i].bytesFilled;
            high->valid = TRUE;
          }
        }
      }
    }
  }
  
  command void TLB.invalid(uint32_t fromPage, uint32_t toPage){
    uint8_t i;
    for(i=0;i<size;i++){
      if(buffer[i].page >= fromPage && buffer[i].page <= toPage){
        buffer[i].valid = FALSE;
      }
    }
  }
}