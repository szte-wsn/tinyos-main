#include "SendData.h"

configuration SendDataAppC {
}
implementation{
	components MainC, LedsC, SendDataP; 
	components new TimerMilliC() as Timer_mes;		/* adatmeres mintaveteli ideje */
	components new TimerMilliC() as Timer_login;	/* sajat node_id kikuldese */
	components ActiveMessageC;

	components new AMReceiverC(AM_GETSLICEMSG) as radRecGetSliceMsg;
	components new AMReceiverC(AM_COMMANDMSG) as radRecCommandMsg;

	components new AMSenderC(AM_LOGINMOTEMSG);

	components SenderC;

	SendDataP -> MainC.Boot;
	SendDataP.Leds -> LedsC;
	SendDataP.Timer_mes -> Timer_mes;
	SendDataP.Timer_login -> Timer_login;
	SendDataP.SplitControl -> ActiveMessageC;
	SendDataP.radRecGetSliceMsg -> radRecGetSliceMsg.Receive;
	SendDataP.radRecCommandMsg -> radRecCommandMsg.Receive;
	SendDataP.AMSend -> AMSenderC;

	SendDataP.Storage -> SenderC;
}
