#include "TestAlarm.h"

configuration TestAlarmC{

}
implementation{

	components MainC, LedsC, TestAlarmP as App;
	components DiagMsgC;
	components new Alarm62khz32C();
	components new AMSenderC(AM_RADIOMSG), ActiveMessageC, new AMReceiverC(AM_RADIOMSG);

	App.Boot->MainC;
	App.SplitControl->ActiveMessageC;
	App.Leds->LedsC;
	App.DiagMsg -> DiagMsgC.DiagMsg;
	/*App.LocalTime -> RFA1DriverLayerC.LocalTimeRadio;*/
	App.Alarm -> Alarm62khz32C;
	App.AMSend -> AMSenderC.AMSend;	 
	App.Receive -> AMReceiverC.Receive;
	App.Packet -> ActiveMessageC;
	App.PacketTimeStampRadio -> ActiveMessageC;

}
