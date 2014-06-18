interface TranslatedStorage{   
   command uint32_t getMaxAddress();
   command error_t getMinAddress();
   event void getMinAddressDone(error_t error, uint32_t address);
   
   command error_t read(uint32_t address, uint32_t len, void* data);
   event void readDone(error_t error, uint32_t readAddress, uint32_t len, void* buffer);
   
   command error_t write(void* data, uint32_t len);
   event void writeDone(error_t error, uint32_t address, uint32_t length, uint32_t lostBytes, void* buffer);
   
   command error_t sync();
   event void syncDone(error_t error, uint32_t lostBytes);
   
   command error_t eraseAll();
   event void eraseAllDone(error_t error);

}