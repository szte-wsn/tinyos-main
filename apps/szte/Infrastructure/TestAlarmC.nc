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

	components MeasureWave2C as MeasureWaveC;
	App.MeasureWave -> MeasureWaveC;

	#ifdef ENABLE_DEBUG_SLOTS
  components new AMSenderC(AM_WAVE_MESSAGE_T);
	App.AMSend -> AMSenderC;
	#endif

	#if defined(TEST_CALCULATION_TIMING)
	components DiagMsgC;
	App.DiagMsg -> DiagMsgC;
	#endif
}

