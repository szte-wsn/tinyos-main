generic module Mcp4x3_5xCommunicationI2cP(uint8_t slaveAddress){
	provides interface Mcp4x3_5xCommunication;
	uses interface I2CPacket<TI2CBasicAddr>;
	uses interface GetNow<uint8_t> as GetAddress;
}
implementation{
	async command error_t Mcp4x3_5xCommunication.write(void* buffer, uint8_t length){
		return call I2CPacket.write(I2C_START | I2C_STOP, slaveAddress, length, buffer);
	}
	
	async command error_t Mcp4x3_5xCommunication.read(void* buffer, uint8_t length){
		return call I2CPacket.read(I2C_START | I2C_STOP, slaveAddress, length, buffer);
	}
	
	async event void I2CPacket.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data){
		signal Mcp4x3_5xCommunication.writeDone(error, length, data);
	}
	
	async event void I2CPacket.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t* data){
		signal Mcp4x3_5xCommunication.readDone(error, length, data);
	}
}
