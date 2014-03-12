#include "TestAlarm.h"

#define NUMBER_OF_MEASURES 3

module TestAlarmP{
	uses interface Boot;
	uses interface AMSend;
	uses interface SplitControl;
	uses interface Leds;
	uses interface DiagMsg;
	//uses interface LocalTime<TRadio> as LocalTime;
	uses interface Alarm<T62khz, uint32_t> as Alarm;
	uses interface Packet;
	uses interface Receive;
	uses interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
}
implementation{

	uint32_t sender_wait[NUMBER_OF_MEASURES];
	uint32_t sender_send[NUMBER_OF_MEASURES];
	uint32_t receiver_wait[NUMBER_OF_MEASURES];
	uint8_t channels[NUMBER_OF_MEASURES];
	uint8_t modes[NUMBER_OF_MEASURES];
	uint8_t trim1[NUMBER_OF_MEASURES];
	uint8_t trim2[NUMBER_OF_MEASURES];
	uint8_t num_of_measures = 0; //how many measures was configured
	uint8_t active_measure;
	bool sender_sends=FALSE, sender_waits=FALSE;
	bool sender[NUMBER_OF_MEASURES]; //TRUE - if the mote is sender during the Ti. measure
	bool receiver[NUMBER_OF_MEASURES]; //TRUE - if the mote is receiver during the Ti. measure
	uint32_t message_received_time;
	message_t packet;

	task void MeasureDone();
	
	event void Boot.booted(){
		call SplitControl.start();
	}
	
	event void SplitControl.startDone(error_t error){
	}

	event void SplitControl.stopDone(error_t error){}
	event void AMSend.sendDone(message_t* msg, error_t error) {
		
	}

	/*LEDS:*****/
	/*LED0 : Waits before receive
	/*LED1 : Waits before sending
	/*LED2 : Sending
	/**/
	
	async event void Alarm.fired(){
		call Leds.set(0);
		if(sender[active_measure]){ //sender 
			if(sender_sends){
				/*Here to stop sending*/

				/**********************/
				if(active_measure < num_of_measures-1){
					active_measure++;
				}else{
					post MeasureDone();
					return;
				}
				if(sender[active_measure]){
					call Alarm.startAt(message_received_time,sender_wait[active_measure]);
					sender_sends = FALSE;
					sender_waits = TRUE;
					call Leds.led1On();
				}else{
					call Alarm.startAt(message_received_time,receiver_wait[active_measure]);
					sender_sends = FALSE;
					sender_waits = FALSE;
					call Leds.led0On();
				}
			}else if(sender_waits){
				/*Here to start sending the Continious wave*/

				/*******************************************/
				call Alarm.startAt(message_received_time,sender_send[active_measure]);	
				sender_sends = TRUE;
				sender_waits = FALSE;	
				call Leds.led2On();		
			}
		}else{ //receiver
			if(active_measure < num_of_measures-1){
					active_measure++;
			}else{
					post MeasureDone();
					return;
			}
			if(sender[active_measure]){
				call Alarm.startAt(message_received_time,sender_wait[active_measure]);
				sender_sends = FALSE;
				sender_waits = TRUE;
				call Leds.led1On();
			}else{
				/*Here to start receiving the Continious wave*/

				/*******************************************/
				call Alarm.startAt(message_received_time,receiver_wait[active_measure]);
				sender_sends = FALSE;
				sender_waits = FALSE;
				call Leds.led0On();
			}			
			
		}		
	}

	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
			config_msg_t* msg = (config_msg_t*)payload;
			int i;
			if(call PacketTimeStampRadio.isValid(bufPtr)){
				message_received_time = call PacketTimeStampRadio.timestamp(bufPtr);
			}
			for(i=0;i<len/sizeof(config_msg_t);i++){
				if(msg->Tsender_send > 0){ //if > 0 then this measure is configured
					num_of_measures++; //how many measures are configured 
					if(TOS_NODE_ID == msg->Tsender1ID || TOS_NODE_ID == msg->Tsender2ID){
						sender[i] = TRUE;//in this measure,is the mote a sender				
					}else{
						sender[i] = FALSE;//not a sender
					}
					receiver[i] = !sender[i]; //if sends than not receives and vice versa
					channels[i] = msg->Tchannel; //wich channel is used
					modes[i] = msg->Tmode; // + - 0,5MHz
					trim1[i] = msg->Ttrim1; // Sender1 trim in this measure
					trim2[i] = msg->Ttrim2; // Sender2 trim in this measure
					sender_wait[i] = msg->Tsender_wait; // sender waits before i. sending
					sender_send[i] = msg->Tsender_send; // sender sends Cont. wave 
					receiver_wait[i] = msg->Treceiver_wait;//receiver waits before i. receive
					msg++;	// [i. config] ---> [i+1. config]	
				}else{
					break;				
				}
			}	
			if(sender[0]){
				call Alarm.startAt(message_received_time,sender_wait[0]);
				sender_waits = TRUE;
				call Leds.led1On();
			}else{
				call Alarm.startAt(message_received_time,receiver_wait[0]);	
				call Leds.led0On();	
			}		
		active_measure = 0;
		return bufPtr;
	}

	task void MeasureDone(){
		//reset variables
		int i=0;
		sender_sends = FALSE;
		sender_waits = FALSE;
		for(i=0;i<NUMBER_OF_MEASURES;i++){
			sender_wait[i]=0;
			sender_send[i]=0;
			receiver_wait[i]=0;
			channels[i]=0;
			modes[i]=0;
			trim1[i]=0;
			trim2[i]=0;
			sender[i]=FALSE;
			receiver[i]=FALSE;
		}
		active_measure = 0;
		num_of_measures = 0;
		message_received_time = 0;
	}

}
