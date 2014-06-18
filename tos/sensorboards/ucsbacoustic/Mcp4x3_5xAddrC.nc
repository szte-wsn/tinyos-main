module Mcp4x3_5xAddrC{
	provides interface GetNow<uint8_t>;
}
implementation{
	async command uint8_t GetNow.getNow(){
		return 0x28;
	}
}