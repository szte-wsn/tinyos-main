configuration MeasureWave2C{
	provides interface MeasureWave;
}
implementation{
	components MeasureWave2P as MeasureWaveP;
	MeasureWave = MeasureWaveP;
	
	#ifdef MEASUREWAVE_PROFILER
	components LocalTimeMicroC, DiagMsgC;
	MeasureWaveP.DiagMsg -> DiagMsgC;
	MeasureWaveP.LocalTime -> LocalTimeMicroC;
	#endif
}