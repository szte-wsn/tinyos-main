interface FramedRead{
	command error_t getMinAddress();
	event void getMinAddressDone(uint32_t addr,error_t error);
	command uint32_t getMaxAddress();
	command error_t read(uint32_t addr, void* buf, uint16_t  len);
	event void readDone(error_t error, void* buffer, uint16_t bufferlen, uint32_t startAddress, uint16_t frameLength, uint32_t nextReadAddress);
}