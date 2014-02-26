interface BootloaderInterface{
  async command void start();
  async command void stop();
  async command void startMainProgram();
  async event void contacted();
  async event void erase(uint32_t address);
  async event void read(uint32_t address);
  async event void write(uint32_t address);
  async event void exitBootloader();
  async command void exitBootloaderReady();
}