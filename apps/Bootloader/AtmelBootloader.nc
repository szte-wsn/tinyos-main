interface AtmelBootloader{
  async command uint16_t getPageSize();
  async command uint32_t getFlashSize();
  async command uint32_t getBootloaderStart();
  
  async command error_t disableFlash();
  async command error_t enableFlash();
  
  async command error_t erasePage(uint32_t address);
  async event void erasePageDone();
  
  async command error_t writePage(uint32_t address, void* data);
  async event void writePageDone();
  
  async command error_t readPage(uint32_t address, void* data);
  
  async command void exitBootloader();
}