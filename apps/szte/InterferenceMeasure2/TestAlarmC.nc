#include "TestAlarm.h"

configuration TestAlarmC{
	
}
implementation{
	components MainC, LedsC, TestAlarmP as App;
	App.Boot->MainC;
	App.Leds->LedsC;
	
	components new Alarm62khz32C();
	App.Alarm -> Alarm62khz32C;
	
	components ActiveMessageC, new AMReceiverC(AM_RADIOMSG);	
	App.SplitControl->ActiveMessageC;
	App.Receive -> AMReceiverC.Receive;
	App.PacketTimeStampRadio -> ActiveMessageC;
  
	components SenderC;
	App.Storage -> SenderC;
	App.StdControl -> SenderC;
	
	components  RFA1ActiveMessageC as RfxlinkAMC, MeasureWaveC;
	App.RadioContinuousWave -> RfxlinkAMC;
	App.MeasureWave -> MeasureWaveC;
	
  #ifdef DELUGE
	components DelugeC;
	DelugeC.Leds -> LedsC;
  #endif
	
	components DiagMsgC;
	App.DiagMsg -> DiagMsgC;
  MeasureWaveC.DiagMsg -> DiagMsgC;
	
}

