interface PhaseFreqCounter{
	
	command error_t startCounter(uint8_t* buffer, uint8_t size);

	event void counterDone();

	command void getPhaseAndFreq(uint8_t* phase, uint8_t* freq);

}
