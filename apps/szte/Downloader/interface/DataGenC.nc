configuration DataGenC {
}
implementation{
	components MainC, LedsC, DataGenP; 
	components new TimerMilliC() as Timer_mes;		/* adatmeres mintaveteli ideje */
	components ActiveMessageC;

	components SenderC;


	DataGenP -> MainC.Boot;
	DataGenP.Leds -> LedsC;
	DataGenP.Timer_mes -> Timer_mes;
	DataGenP.SplitControl -> ActiveMessageC;

	DataGenP.Storage -> SenderC;
}
