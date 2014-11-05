configuration MeasureWave2C{
	provides interface MeasureWave;
}
implementation{
	components MeasureWave2P as MeasureWaveP;
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