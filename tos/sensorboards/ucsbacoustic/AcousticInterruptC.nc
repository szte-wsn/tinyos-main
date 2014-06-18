configuration AcousticInterruptC{
	provides interface AcousticInterrupt;
	provides interface SplitControl;
}
implementation{
	components AcousticInterruptP, Ad524xC, MicPowerManagerC, new TimerMilliC();
	AcousticInterrupt = AcousticInterruptP;
	SplitControl = AcousticInterruptP;
	
	AcousticInterruptP.SubControl -> Ad524xC;
	AcousticInterruptP.MicPowerManager -> MicPowerManagerC;
	AcousticInterruptP.WriteAmp -> Ad524xC.Write1;
	AcousticInterruptP.WriteTh -> Ad524xC.Write2;
	AcousticInterruptP.GetAmp -> Ad524xC.Get1;
	AcousticInterruptP.GetTh -> Ad524xC.Get2;
	AcousticInterruptP.Timer -> TimerMilliC;
	
	components MicaBusC;
	AcousticInterruptP.GpioInterrupt -> MicaBusC.Int3_Interrupt;
}