//#include "AM.h"
#include "Sender.h"


configuration SenderC {
	provides {
		interface Storage;
	}
}
implementation {
	components SenderP,LedsC;
	components new AMSenderC(AM_MEASUREMSG) as radSenMeasureMsg;
	components new AMSenderC(AM_ANNOUNCEMENTMSG) as radSenAnnouncementMsg;		

	SenderP = Storage;
	SenderP.Leds -> LedsC;
	SenderP.radSenMeasureMsg -> radSenMeasureMsg.AMSend;
	SenderP.radSenAnnouncementMsg -> radSenAnnouncementMsg.AMSend;
}
