#include "BaseStation.h"

module BaseStationP
{
  uses interface Leds;
  uses interface Boot;
  uses interface SplitControl as RadioControl;
  uses interface SplitControl as SerialControl;

  uses interface Receive as serRecGetsliceMsg;
  uses interface Receive as serRecCommandMsg;

  uses interface AMSend as serSenRadioDataMsg;
  uses interface AMSend as serSenMesNumberMsg;
  uses interface AMSend as serSenLoginMoteMsg;

  uses interface Receive as radRecRadioDataMsg;
  uses interface Receive as radRecMesNumberMsg;
  uses interface Receive as radRecLoginMoteMsg;

  uses interface AMSend as radSenGetsliceMsg;
  uses interface AMSend as radSenCommandMsg;
}
implementation
{
	data_t buffer[MAX_MEASUREMENT_NUMBER];
	message_t pkt;
  	message_t freeMsg;
  	message_t *freeMsgPtr=&freeMsg;

	event void Boot.booted() {
		call RadioControl.start();
		call SerialControl.start();
	}

	event void RadioControl.startDone(error_t err){
		if(err!=SUCCESS){
			call RadioControl.start();
		}
	}

	event void RadioControl.stopDone(error_t err){}

	event void SerialControl.startDone(error_t err){
		if(err==SUCCESS){
			call RadioControl.start();
		}else{
			call SerialControl.start();
		}
	}

	event void SerialControl.stopDone(error_t err){}

/**********SERIAL PORT********/
//Receive
	event message_t* serRecGetsliceMsg.receive(message_t* msg, void* payload, uint8_t len)
	{
		
		if(len == sizeof(GetSliceMsg)) {
			GetSliceMsg* btrpkt = (GetSliceMsg*) (call radSenGetsliceMsg.getPayload(msg, sizeof(GetSliceMsg)));
			if(call radSenGetsliceMsg.send(btrpkt -> node_id, msg, sizeof(GetSliceMsg))==SUCCESS){
			}
		}
	 	return msg;
	}

	event message_t* serRecCommandMsg.receive(message_t* msg, void* payload, uint8_t len)
	{
		if(len == sizeof(CommandMsg)) {
			if(call radSenCommandMsg.send(AM_BROADCAST_ADDR, msg, sizeof(CommandMsg))==SUCCESS){
			}
		}
		return msg;
	}

//Send
	event void serSenRadioDataMsg.sendDone(message_t *msg, error_t err) {
		freeMsgPtr=msg;
	}

	event void serSenMesNumberMsg.sendDone(message_t *msg, error_t err) {
		freeMsgPtr=msg;
	}

	event void serSenLoginMoteMsg.sendDone(message_t *msg, error_t err) {
		freeMsgPtr=msg;
	}

/************RADIO**********/
//Receive
	event message_t* radRecRadioDataMsg.receive(message_t* msg, void* payload, uint8_t len)
	{
		if(len == sizeof(RadioDataMsg)) {	
			if(call serSenRadioDataMsg.send(AM_BROADCAST_ADDR, msg, sizeof(RadioDataMsg))==SUCCESS) {
			}
		}
		return freeMsgPtr; 
	}

	event message_t* radRecMesNumberMsg.receive(message_t* msg, void* payload, uint8_t len)
	{
		if(len == sizeof(MesNumberMsg)) {
			if(call serSenMesNumberMsg.send(AM_BROADCAST_ADDR, msg, sizeof(MesNumberMsg))==SUCCESS) {
			}
		}
		return freeMsgPtr; 
	}


	event message_t* radRecLoginMoteMsg.receive(message_t* msg, void* payload, uint8_t len)
	{
		if(len == sizeof(LoginMoteMsg)) {
			if(call serSenLoginMoteMsg.send(AM_BROADCAST_ADDR, msg, sizeof(LoginMoteMsg))==SUCCESS) {
			}
		}
		return freeMsgPtr; 
	}
//Send
	event void radSenGetsliceMsg.sendDone(message_t* msg, error_t error){
	}

	event void radSenCommandMsg.sendDone(message_t* msg, error_t error){
	}
}
