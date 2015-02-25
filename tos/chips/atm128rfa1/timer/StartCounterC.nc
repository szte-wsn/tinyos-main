generic module StartHplCounterC(typedef size_type @integer(), uint8_t mode){
	provides interface Init;
	uses interface HplAtmegaCounter<size_type>;
}
implementation{
	command error_t Init.init()
	{
		call HplAtmegaCounter.setMode(mode);
		call HplAtmegaCounter.start();

		return SUCCESS;
	}
	
	async event void HplAtmegaCounter.overflow(){}
}