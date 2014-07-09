module PhaseFreqCounterP{
	provides interface PhaseFreqCounter;
}
implementation{

	uint8_t mphase,mfreq;

	command error_t PhaseFreqCounter.startCounter(uint8_t* buffer, uint8_t size){
		//count phase and freq
		mphase = 5;
		mfreq = 10;
		signal PhaseFreqCounter.counterDone();
		return SUCCESS;
	}

	command void PhaseFreqCounter.getPhaseAndFreq(uint8_t* phase, uint8_t* freq){
		*phase = mphase;
		*freq = mfreq;
	}

}
