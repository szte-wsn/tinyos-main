#include "TestAlarm.h"

configuration TestAlarmC{

}
implementation{
	components MainC, LedsC, TestAlarmP as App;
	App.Boot->MainC;
	App.Leds->LedsC;

	components new AlarmMcu32C();
	App.Alarm -> AlarmMcu32C;

	components ActiveMessageC;
	App.SplitControl->ActiveMessageC;
	

	components TimeSyncMessageC;
	App.TimeSyncAMSend -> TimeSyncMessageC.TimeSyncAMSendRadio[AM_SYNCMSG];
	App.TimeSyncPacket -> TimeSyncMessageC.TimeSyncPacketRadio;
	App.SyncReceive -> TimeSyncMessageC.Receive[AM_SYNCMSG];

	components  RFA1ActiveMessageC as RfxlinkAMC;
	App.RadioContinuousWave -> RfxlinkAMC;

	components MeasureWave3C as MeasureWaveC;
	App.MeasureWave -> MeasureWaveC;
	
	components MeasureSettingsC;
	App.MeasureSettings -> MeasureSettingsC;
	
	#ifdef ENABLE_AUTOTRIM
	components AutoTrimC as AutoTrimC;
	App.AutoTrim -> AutoTrimC;
	App.AMPacket -> ActiveMessageC;
	#endif

	#ifdef ENABLE_DEBUG_SLOTS
  components new AMSenderC(AM_WAVE_MESSAGE_T), new TimerMilliC(), BusyWaitMicroC;
	App.AMSend -> AMSenderC;
	App.Timer -> TimerMilliC;
	App.BusyWait -> BusyWaitMicroC;
	#endif

	#if defined(TEST_CALCULATION_TIMING)
	components DiagMsgC;
	App.DiagMsg -> DiagMsgC;
	#endif
	
	
}

