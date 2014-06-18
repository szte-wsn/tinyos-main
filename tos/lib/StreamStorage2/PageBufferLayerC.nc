generic configuration PageBufferLayerC(uint8_t size){
	uses interface PageAllocator;
	provides interface PageBuffer;
}
implementation{
	components new PageBufferLayerP(size), MainC;
	PageAllocator = PageBufferLayerP;
	PageBuffer = PageBufferLayerP;
	
	PageBufferLayerP.Init <- MainC.SoftwareInit;
	
	components NoDiagMsgC as DiagMsgC;
	PageBufferLayerP.DiagMsg -> DiagMsgC;
}