configuration PhaseFreqCounterC{
	provides interface PhaseFreqCounter;
}
implementation{
	components PhaseFreqCounterP;
	PhaseFreqCounter = PhaseFreqCounterP;
}
