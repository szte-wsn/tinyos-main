configuration MeasureWaveC{
	provides interface MeasureWave;
}
implementation{
	components MeasureWaveP;
	MeasureWave = MeasureWaveP;
	
	components BartlettC as FilterC;
	MeasureWaveP.Filter -> FilterC;
	
	#ifdef DEBUG_MEASUREWAVE
	components DiagMsgC;
	MeasureWaveP.DiagMsg -> DiagMsgC;
	#endif
}