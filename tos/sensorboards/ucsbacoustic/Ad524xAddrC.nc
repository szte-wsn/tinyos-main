module Ad524xAddrC{
	provides interface GetNow<uint8_t>;
}
implementation{
	async command uint8_t GetNow.getNow(){
		return 0x2e;
	}
}