generic configuration Mcp4x3_5xI2cC(uint8_t slaveAddress, bool dontSleep0, bool dontSleep1, bool dontturnoff0, bool dontturnoff1)
{
	provides interface Write<uint16_t> as Write0;
	provides interface Write<uint16_t> as Write1;
	provides interface Read<uint16_t> as Read0;
	provides interface Read<uint16_t> as Read1;
	provides interface SplitControl as Control0;
	provides interface SplitControl as Control1;
}
implementation
{
	components new Mcp4x3_5xP(0, 0, dontSleep0, dontturnoff0) as Pot0, new Mcp4x3_5xP(4, 1, dontSleep1, dontturnoff1) as Pot1, MainC,
						 new Mcp4x3_5xCommunicationI2cP(slaveAddress) as Pot0Comm, new Mcp4x3_5xCommunicationI2cP(slaveAddress) as Pot1Comm;
	Write0 = Pot0.Write;
	Write1 = Pot1.Write;
	Read0 = Pot0.Read;
	Read1 = Pot1.Read;
	Control0 = Pot0.SplitControl;
	Control1 = Pot1.SplitControl;
	
	Pot0.Mcp4x3_5xCommunication -> Pot0Comm;
	Pot1.Mcp4x3_5xCommunication -> Pot1Comm;
	
	Pot0.Init <- MainC.SoftwareInit;
	Pot1.Init <- MainC.SoftwareInit;
	
	Pot0.OtherTCONPart -> Pot1.MyTCONPart;
	Pot1.OtherTCONPart -> Pot0.MyTCONPart;
	
	components new HplMcp4x3_5xI2cC() as Pot0I2C, new HplMcp4x3_5xI2cC() as Pot1I2C;
	
	Pot0Comm.I2CPacket -> Pot0I2C;
	Pot1Comm.I2CPacket -> Pot1I2C;
	
	Pot0.Resource -> Pot0I2C;
	Pot1.Resource -> Pot1I2C;
	
	Pot0.SelfPower -> Pot0I2C;
	Pot1.SelfPower -> Pot1I2C;
	
	components NoDiagMsgC as DiagMsgC;
	Pot0.DiagMsg -> DiagMsgC;
	Pot1.DiagMsg -> DiagMsgC;
}