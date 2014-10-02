#include "TestAlarm.h"

configuration TestAlarmC{
	
}
implementation{
	components MainC, LedsC, TestAlarmP as App;
	App.Boot->MainC;
	App.Leds->LedsC;
	
	components new Alarm62khz32C();
	App.Alarm -> Alarm62khz32C;
	
	components ActiveMessageC;	
	App.SplitControl->ActiveMessageC;

	components TimeSyncMessageC;
	App.TimeSyncAMSend -> TimeSyncMessageC.TimeSyncAMSendRadio[AM_SYNCMSG];
	App.TimeSyncPacket -> TimeSyncMessageC.TimeSyncPacketRadio;
	App.SyncReceive -> TimeSyncMessageC.Receive[AM_SYNCMSG];
	
	components  RFA1ActiveMessageC as RfxlinkAMC;
	App.RadioContinuousWave -> RfxlinkAMC;

	components MeasureWaveC;
	App.MeasureWave -> MeasureWaveC;	
	
	#ifdef SEND_WAVEFORM
	components new AMSenderC(AM_RADIOMSG);
	App.AMSend -> AMSenderC;
	#endif
}

