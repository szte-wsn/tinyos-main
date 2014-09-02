#include "TestAlarm.h"

configuration TestAlarmC{
	
}
implementation{
	components MainC, LedsC, TestAlarmP as App;
	App.Boot->MainC;
	App.Leds->LedsC;
	
	components new Alarm62khz32C();
	App.Alarm -> Alarm62khz32C;
	
	components ActiveMessageC, new AMSenderC(AM_RADIOMSG);	
	App.SplitControl->ActiveMessageC;
	App.Packet -> ActiveMessageC;
	
	App.AMSend -> AMSenderC;
	App.AMPacket -> AMSenderC;

	components TimeSyncMessageC;
	App.TimeSyncAMSend -> TimeSyncMessageC.TimeSyncAMSendRadio[AM_SYNCMSG];
	App.TimeSyncPacket -> TimeSyncMessageC.TimeSyncPacketRadio;
	App.SyncReceive -> TimeSyncMessageC.Receive[AM_SYNCMSG];
	
	components  RFA1ActiveMessageC as RfxlinkAMC;
	App.RadioContinuousWave -> RfxlinkAMC;

	components MeasureWaveC;
	App.MeasureWave -> MeasureWaveC;
	#ifdef DEBUG_MEASUREWAVE
	components DiagMsgC;
	MeasureWaveC.DiagMsg -> DiagMsgC;
	#endif
	
}

