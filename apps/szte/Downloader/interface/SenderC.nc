//#include "AM.h"
#include "Sender.h"


configuration SenderC {
	provides {
		interface Storage;
	}
}
implementation {
	components SenderP;
	components new AMSenderC(AM_SENDERMSG) as SenderMsg;
	components new AMSenderC(AM_MESNUMBERMSG) as MesNumberMsg;		

	SenderP = Storage;
	SenderP.radSenSenderMsg -> SenderMsg.AMSend;
	SenderP.radSenMesNumberMsg -> MesNumberMsg.AMSend;
}
