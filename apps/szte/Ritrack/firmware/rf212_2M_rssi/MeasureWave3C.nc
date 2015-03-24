configuration MeasureWave3C{
	provides interface MeasureWave;
}
implementation{
	components MeasureWave3P as MeasureWaveP;
	MeasureWave = MeasureWaveP;
	
	#ifdef MEASUREWAVE_PROFILER
	components LocalTimeMicroC, DiagMsgC;
	MeasureWaveP.DiagMsg -> DiagMsgC;
	MeasureWaveP.LocalTime -> LocalTimeMicroC;
	#endif
}