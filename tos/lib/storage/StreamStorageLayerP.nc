generic module StreamStorageLayerP(){
  provides interface StreamStorageErase;
  provides interface StreamStorageRead;
  provides interface StreamStorageWrite;
  uses interface TranslatedStorage;
}
implementation{
  enum{
    S_APPEND_ID,
    S_APPEND_AFTER_ID,
    S_OTHER,
  };
  
  uint8_t state = S_OTHER;
  void* storedBuffer;
  uint16_t storedLen;
  
  command error_t StreamStorageWrite.appendWithID(nx_uint8_t id, void* buf, uint16_t  len){
    if( state != S_OTHER )
      return EBUSY;
    else {
      error_t err;
      state = S_APPEND_ID;
      storedBuffer = buf;
      storedLen = len;
      err = call TranslatedStorage.write(&id, 1);
      if( err != SUCCESS )
        state = S_OTHER;
      return err;
    }
  }
  
  command error_t StreamStorageWrite.append(void* buf, uint16_t  len){
    return call TranslatedStorage.write(buf, len);
  }
  
  event void TranslatedStorage.writeDone(error_t error, uint32_t address, uint32_t length, uint32_t lostBytes, void* buffer){
    if( state == S_APPEND_ID ){
      error_t err;
      state = S_APPEND_AFTER_ID;
      err = ecombine(error, call TranslatedStorage.write(storedBuffer, storedLen));
      if( err!= SUCCESS ){
        state = S_OTHER;
        signal StreamStorageWrite.appendDoneWithID(storedBuffer, storedLen, err);
      }
    } else if( state == S_APPEND_AFTER_ID){
      state = S_OTHER;
      signal StreamStorageWrite.appendDoneWithID(storedBuffer, storedLen, error);
    } else {
      signal StreamStorageWrite.appendDone(buffer, length, error);
    }
  }
  
  command error_t StreamStorageWrite.sync(){
    return call TranslatedStorage.sync();
  }
  
  event void TranslatedStorage.syncDone(error_t error, uint32_t lostBytes){
    signal StreamStorageWrite.syncDone(error);
  }
  
  command error_t StreamStorageRead.getMinAddress(){
    return call TranslatedStorage.getMinAddress();
  }
  
  event void TranslatedStorage.getMinAddressDone(error_t error, uint32_t addr){
    signal StreamStorageRead.getMinAddressDone(addr, error);
  }
  
  command uint32_t StreamStorageRead.getMaxAddress(){ 
    return call TranslatedStorage.getMaxAddress();
  }
  
  command error_t StreamStorageRead.read(uint32_t addr, void* buf, uint8_t  len){
    return call TranslatedStorage.read(addr, len, buf);
  }
  
  event void TranslatedStorage.readDone(error_t error, uint32_t readAddress, uint32_t length, void* buffer){
    signal StreamStorageRead.readDone(buffer, length, error);
  }
  
  command error_t StreamStorageErase.erase(){
    return call TranslatedStorage.eraseAll();
  }
  
  event void TranslatedStorage.eraseAllDone(error_t error){
    signal StreamStorageErase.eraseDone(error);
  }
  
  default event void StreamStorageErase.eraseDone(error_t error){}
  default event void StreamStorageRead.getMinAddressDone(uint32_t addr,error_t error){}
  default event void StreamStorageRead.readDone(void* buf, uint8_t  len, error_t error){}
  default event void StreamStorageWrite.appendDoneWithID(void* buf, uint16_t  len, error_t error){}
  default event void StreamStorageWrite.appendDone(void* buf, uint16_t  len, error_t error){}
  default event void StreamStorageWrite.syncDone(error_t error){}
}