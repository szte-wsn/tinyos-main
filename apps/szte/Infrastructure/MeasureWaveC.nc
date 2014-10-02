configuration MeasureWaveC{
	provides interface MeasureWave;
}
implementation{
	components MeasureWaveP;
	MeasureWave = MeasureWaveP;
	
	#if defined(DEBUG_MEASUREWAVE) || defined(DEBUG_FILTER)
	components DiagMsgC;
	MeasureWaveP.DiagMsg -> DiagMsgC;
	#endif
}