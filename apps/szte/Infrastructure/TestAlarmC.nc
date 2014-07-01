#include "TestAlarm.h"

configuration TestAlarmC{
	
}
implementation{
	components MainC, LedsC, TestAlarmP as App;
	App.Boot->MainC;
	App.Leds->LedsC;
	
	components new Alarm62khz32C();
	App.Alarm -> Alarm62khz32C;
	
	components ActiveMessageC, new AMReceiverC(AM_RADIOMSG), new AMSenderC(AM_RADIOMSG), new AMSenderC(AM_RSSIDATADONE_T) as RssiDone;	
	App.SplitControl->ActiveMessageC;
	App.Receive -> AMReceiverC.Receive;
	App.Packet -> ActiveMessageC;
	App.PacketTimeStampRadio -> ActiveMessageC;
	
	App.AMSend -> AMSenderC;
	App.RssiDone -> RssiDone;
	App.AMPacket -> AMSenderC;
	App.PacketAcknowledgements -> AMSenderC;

	components TimeSyncMessageC;
	App.TimeSyncAMSend 	-> TimeSyncMessageC.TimeSyncAMSendRadio[AM_SYNCMSG];
	App.TimeSyncPacket 	-> TimeSyncMessageC.TimeSyncPacketRadio;
	App.SyncReceive 	-> TimeSyncMessageC.Receive[AM_SYNCMSG];
	
	components  RFA1ActiveMessageC as RfxlinkAMC;
	App.RadioContinuousWave -> RfxlinkAMC;
	
	components DelugeC;
	DelugeC.Leds -> LedsC;
	
	components DiagMsgC;
	components SerialActiveMessageC;
	App.DiagMsg -> DiagMsgC.DiagMsg;
	App.SerialSplitControl -> SerialActiveMessageC.SplitControl;

	
	
}

