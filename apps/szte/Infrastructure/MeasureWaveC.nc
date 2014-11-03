configuration MeasureWaveC{
	provides interface MeasureWave;
}
implementation{
	components MeasureWaveP;
	MeasureWave = MeasureWaveP;
	
	#if defined(DEBUG_MEASUREWAVE) || defined(DEBUG_FILTER) || defined(MEASUREWAVE_PROFILER)
	components DiagMsgC;
	MeasureWaveP.DiagMsg -> DiagMsgC;
	#endif
	#ifdef MEASUREWAVE_PROFILER
	components LocalTimeMicroC;
	MeasureWaveP.LocalTime -> LocalTimeMicroC;
	#endif
}