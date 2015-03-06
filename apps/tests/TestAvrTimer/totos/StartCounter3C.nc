configuration StartCounter3C{
}
implementation{
	components HplAtmRfa1Timer3C as HplAtmegaTimerC;
	
	components new StartCounterP(uint16_t, MCU_TIMER_MODE);
	StartCounterP.HplAtmegaCounter -> HplAtmegaTimerC;
	components McuInitC;
	McuInitC.TimerInit -> StartCounterP;
}