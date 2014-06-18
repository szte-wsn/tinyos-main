generic configuration Mcp4x3_5xSpiC(uint8_t gpioNum, bool dontSleep0, bool dontSleep1, bool dontturnoff0, bool dontturnoff1)
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
	components new Mcp4x3_5xP(0, 0, dontSleep0, dontturnoff0) as Pot0, new Mcp4x3_5xP(4, 1, dontSleep1, dontturnoff1) as Pot1,
	new Mcp4x3_5xCommunicationSpiP() as Pot0Comm, new Mcp4x3_5xCommunicationSpiP() as Pot1Comm;
	Write0 = Pot0.Write;
	Write1 = Pot1.Write;
	Read0 = Pot0.Read;
	Read1 = Pot1.Read;
	Control0 = Pot0.SplitControl;
	Control1 = Pot1.SplitControl;
	
	components HplMcp4x3_5xSpiC, LedsC, MainC;
	Pot0Comm.CS -> HplMcp4x3_5xSpiC.ChipSelect[gpioNum];
	Pot1Comm.CS -> HplMcp4x3_5xSpiC.ChipSelect[gpioNum];
	
	Pot0.Mcp4x3_5xCommunication -> Pot0Comm;
	Pot1.Mcp4x3_5xCommunication -> Pot1Comm;
	Pot0.StdControl -> Pot0Comm;
	Pot1.StdControl -> Pot1Comm;
	
	Pot0Comm.SpiPacket -> HplMcp4x3_5xSpiC.Pot0SpiPacket;
	Pot1Comm.SpiPacket -> HplMcp4x3_5xSpiC.Pot1SpiPacket;
	
	Pot0.Resource -> HplMcp4x3_5xSpiC.Pot0SpiResource;
	Pot1.Resource -> HplMcp4x3_5xSpiC.Pot1SpiResource;
	
	Pot0.OtherTCONPart -> Pot1.MyTCONPart;
	Pot1.OtherTCONPart -> Pot0.MyTCONPart;
	
	Pot0.SelfPower -> HplMcp4x3_5xSpiC.SelfPower;
	Pot1.SelfPower -> HplMcp4x3_5xSpiC.SelfPower;
	
	Pot0.Init <- MainC.SoftwareInit;
	Pot1.Init <- MainC.SoftwareInit;
	
	components NoDiagMsgC as DiagMsgC;
	Pot0.DiagMsg -> DiagMsgC;
	Pot1.DiagMsg -> DiagMsgC;
}