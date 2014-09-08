interface BootloaderInterface{
  async command error_t start();
  async command error_t stop();
  async command void startMainProgram();
  async event void contacted();
  async event void erase(uint32_t address);
  async event void read(uint32_t address);
  async event void write(uint32_t address);
  async event void exitBootloader(bool programmingSuccessful);
  async command void exitBootloaderReady();
}