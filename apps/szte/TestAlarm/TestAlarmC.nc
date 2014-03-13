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
	
	components RFA1DriverLayerC as DriverLayerC, RFA1ActiveMessageC as RfxlinkAMC;
	App.RssiMonitor -> DriverLayerC;
	App.AtmelRadioTest -> DriverLayerC;
	App.SetXtalTrim -> DriverLayerC;
	App.RadioChannel -> RfxlinkAMC;
	
	components DelugeC;
	DelugeC.Leds -> LedsC;
	
	components DiagMsgC;
	App.DiagMsg -> DiagMsgC;
	
}

