#include "SendData.h"

configuration SendDataAppC {
}
implementation{
	components MainC, LedsC, SendDataP; 
	components new TimerMilliC() as Timer_mes;		/* adatmeres mintaveteli ideje */
	components ActiveMessageC;

	components new AMReceiverC(AM_GETSLICEMSG) as radRecGetSliceMsg;
	components new AMReceiverC(AM_COMMANDMSG) as radRecCommandMsg;
	components new AMReceiverC(AM_FREEMSG) as radRecFreeMsg;	

	components new AMSenderC(AM_COMMANDMSG);

	components SenderC;

	SendDataP -> MainC.Boot;
	SendDataP.Leds -> LedsC;
	SendDataP.Timer_mes -> Timer_mes;
	SendDataP.SplitControl -> ActiveMessageC;
	SendDataP.radRecGetSliceMsg -> radRecGetSliceMsg.Receive;
	SendDataP.radRecCommandMsg -> radRecCommandMsg.Receive;
	SendDataP.radRecFreeMsg -> radRecFreeMsg.Receive;
	SendDataP.AMSend -> AMSenderC;

	SendDataP.Storage -> SenderC;
}
