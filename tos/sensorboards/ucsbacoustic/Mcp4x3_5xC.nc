configuration Mcp4x3_5xC{
	provides interface Write<uint16_t> as Write0;
	provides interface Write<uint16_t> as Write1;
	provides interface Read<uint16_t> as Read0;
	provides interface Read<uint16_t> as Read1;
	provides interface SplitControl as Control0;
	provides interface SplitControl as Control1;
}
implementation{
	components new Mcp4x3_5xI2cC(0x28, FALSE, FALSE, FALSE, FALSE);
	Write0 = Mcp4x3_5xI2cC.Write0;
	Write1 = Mcp4x3_5xI2cC.Write1;
	Read0 = Mcp4x3_5xI2cC.Read0;
	Read1 = Mcp4x3_5xI2cC.Read1;
	Control0 = Mcp4x3_5xI2cC.Control0;
	Control1 = Mcp4x3_5xI2cC.Control1;
}