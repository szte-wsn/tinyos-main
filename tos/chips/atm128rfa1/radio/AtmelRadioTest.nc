interface AtmelRadioTest{
	async command error_t startCWTest(uint8_t ch, uint8_t power, uint8_t mode);
	async event void startCWTestDone(uint8_t ch, uint8_t power, uint8_t mode);
  
  async command error_t startModulatedTest(uint8_t ch, uint8_t power, uint8_t mode, void* data, uint8_t len);
  async event void startModulatedTestDone(uint8_t ch, uint8_t power, uint8_t mode, void* data, uint8_t len);
	async command error_t stopTest();
	async event void stopTestDone();
}