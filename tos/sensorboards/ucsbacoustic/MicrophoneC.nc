configuration MicrophoneC{
	provides interface Read<uint16_t>;
	provides interface ReadStream<uint16_t>;
	provides interface Write<uint16_t> as FirstAmp;
	provides interface Write<uint16_t> as SecondAmp;
}
implementation{
	components MicrophoneP, GainOpAmpsPowerManagerC, MicPowerManagerC, Mcp4x3_5xC, MainC;
	components new AdcReadClientC(), new AdcReadStreamClientC(), MicaBusC, new TimerMilliC();
	Read = MicrophoneP;
	ReadStream = MicrophoneP;
	FirstAmp = MicrophoneP.Amp1;
	SecondAmp = MicrophoneP.Amp2;
	
	MicrophoneP.OpAmps -> GainOpAmpsPowerManagerC;
	MicrophoneP.Mic -> MicPowerManagerC;
	MicrophoneP.Init <- MainC.SoftwareInit;
	
	MicrophoneP.Amp1Control -> Mcp4x3_5xC.Control0;
	MicrophoneP.Amp2Control -> Mcp4x3_5xC.Control1;
	MicrophoneP.SubAmp1-> Mcp4x3_5xC.Write0;
	MicrophoneP.SubAmp2-> Mcp4x3_5xC.Write1;
	
	MicrophoneP.MicaBusAdc -> MicaBusC.Adc1;
	
	AdcReadClientC.Atm128AdcConfig -> MicrophoneP;
	MicrophoneP.SubRead -> AdcReadClientC;
	
	AdcReadStreamClientC.Atm128AdcConfig -> MicrophoneP;
	MicrophoneP.SubReadStream -> AdcReadStreamClientC;
	
	MicrophoneP.Timer -> TimerMilliC;
	
	components NoDiagMsgC as DiagMsgC;
	MicrophoneP.DiagMsg -> DiagMsgC;
}