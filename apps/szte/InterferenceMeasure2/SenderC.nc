#include "Sender.h"


configuration SenderC {
	provides {
		interface Storage;
		interface StdControl;
	}
}
implementation {
	components LedsC, SenderP;

	components new AMSenderC(AM_MEASUREMSG) as radSenMeasureMsg;
	components new AMSenderC(AM_ANNOUNCEMENTMSG) as radSenAnnouncementMsg;	
	components new AMReceiverC(AM_GETSLICEMSG) as radRecGetSliceMsg;
	components new AMReceiverC(AM_COMMANDMSG) as radRecCommandMsg;
	components new AMReceiverC(AM_FREEMSG) as radRecFreeMsg;	

	Storage = SenderP;
	StdControl = SenderP;
	SenderP.Leds -> LedsC;

	SenderP.radSenMeasureMsg -> radSenMeasureMsg.AMSend;
	SenderP.radSenAnnouncementMsg -> radSenAnnouncementMsg.AMSend;
	SenderP.radRecGetSliceMsg -> radRecGetSliceMsg.Receive;
	SenderP.radRecCommandMsg -> radRecCommandMsg.Receive;
	SenderP.radRecFreeMsg -> radRecFreeMsg.Receive;
}
