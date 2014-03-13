#include "BaseStation.h"

configuration BaseStationC {
}
implementation {
  components MainC;
  components LedsC;
  components BaseStationP as App;

  components ActiveMessageC;
  components SerialActiveMessageC;

  components new SerialAMReceiverC(AM_GETSLICEMSG) as serRecGetsliceMsg;
  components new SerialAMReceiverC(AM_COMMANDMSG) as serRecCommandMsg;

  components new SerialAMSenderC(AM_RADIODATAMSG) as serSenRadioDataMsg;
  components new SerialAMSenderC(AM_MESNUMBERMSG) as serSenMesNumberMsg;
  components new SerialAMSenderC(AM_LOGINMOTEMSG) as serSenLoginMoteMsg;

  components new AMReceiverC(AM_RADIODATAMSG) as radRecRadioDataMsg;
  components new AMReceiverC(AM_MESNUMBERMSG) as radRecMesNumberMsg;
  components new AMReceiverC(AM_LOGINMOTEMSG) as radRecLoginMoteMsg;

  components new AMSenderC(AM_GETSLICEMSG)  as radSenGetsliceMsg;
  components new AMSenderC(AM_COMMANDMSG) as radSenCommandMsg;

  App.Boot -> MainC;
  App.Leds -> LedsC;

  App.RadioControl -> ActiveMessageC;
  App.SerialControl-> SerialActiveMessageC;

  App.serRecGetsliceMsg -> serRecGetsliceMsg;
  App.serRecCommandMsg -> serRecCommandMsg;

  App.serSenRadioDataMsg -> serSenRadioDataMsg;
  App.serSenMesNumberMsg -> serSenMesNumberMsg;
  App.serSenLoginMoteMsg -> serSenLoginMoteMsg;

  App.radSenGetsliceMsg -> radSenGetsliceMsg.AMSend;
  App.radSenCommandMsg -> radSenCommandMsg.AMSend;

  App.radRecRadioDataMsg -> radRecRadioDataMsg.Receive;
  App.radRecMesNumberMsg -> radRecMesNumberMsg.Receive;
  App.radRecLoginMoteMsg -> radRecLoginMoteMsg.Receive;
}
