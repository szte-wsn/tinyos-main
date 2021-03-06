
module Si443xOffP 
{
	provides interface Init as Stm25pOff;
	uses interface Resource as SpiResource;
	uses interface GeneralIO as CSN;
	uses interface GeneralIO as IO;
	uses interface GeneralIO as IRQ;
	
	uses interface SpiByte;
}
implementation 
{

	command error_t Stm25pOff.init() 
	{
		if(!uniqueCount("Si443xRadioOn")) {
			call CSN.makeOutput();
			call CSN.set();
			
			call IO.makeInput();
			call IO.clr();
			
			call IRQ.makeInput();
			call IRQ.set();
			
			if( call SpiResource.immediateRequest() == SUCCESS ){ //should be success
				call CSN.clr();
				call SpiByte.write((1 << 7) | 0x05);
				call SpiByte.write(0x00);
				call SpiByte.write(0x00);
				call SpiByte.write(0x00);
				call CSN.set();
				
				call SpiResource.release();
			} else
				call SpiResource.request();
		}
		return SUCCESS;
	}

	event void SpiResource.granted() {}
}
