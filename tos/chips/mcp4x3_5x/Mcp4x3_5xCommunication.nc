interface Mcp4x3_5xCommunication{
	async command error_t write(void* buffer, uint8_t length);
	async event void writeDone(error_t err, uint8_t length, void* buffer);
	async command error_t read(void* buffer, uint8_t length);
	async event void readDone(error_t err, uint8_t length, void* buffer);
}