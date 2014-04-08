#include "TestAlarm.h"

configuration TestAlarmC{
	
}
implementation{
	components MainC, LedsC, TestAlarmP as App;
	App.Boot->MainC;
	App.Leds->LedsC;
	
	components new Alarm62khz32C();
	App.Alarm -> Alarm62khz32C;
	
	components ActiveMessageC, new AMReceiverC(AM_RADIOMSG), new AMSenderC(AM_RSSIMESSAGE_T), new AMSenderC(AM_RSSIDATADONE_T) as RssiDone;	
	App.SplitControl->ActiveMessageC;
	App.Receive -> AMReceiverC.Receive;
	App.Packet -> ActiveMessageC;
	App.PacketTimeStampRadio -> ActiveMessageC;
	
	App.AMSend -> AMSenderC;
	App.RssiDone -> RssiDone;
	App.AMPacket -> AMSenderC;
	App.PacketAcknowledgements -> AMSenderC;
	
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

