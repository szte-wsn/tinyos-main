#include "TestAlarm.h"

#define NUMBER_OF_MEASURES 3
#define BUFFER_LEN 2048

module TestAlarmP{
	uses interface Boot;
	uses interface SplitControl;
	uses interface Leds;
	
	uses interface Alarm<T62khz, uint32_t> as Alarm;
	uses interface Receive;
	uses interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
	
	uses interface RssiMonitor;
	uses interface AtmelRadioTest;
	uses interface SetNow<uint8_t> as SetXtalTrim;
	uses interface RadioChannel;
	
	uses interface AMSend;
	uses interface AMSend as RssiDone;
	uses interface AMPacket;
	uses interface Packet;
	uses interface PacketAcknowledgements;
	
	uses interface DiagMsg;
}
implementation{
	uint8_t buffer[NUMBER_OF_MEASURES][BUFFER_LEN];
	uint32_t measureTime[NUMBER_OF_MEASURES];
	uint16_t controller;
	message_t messageBuf;

	uint32_t sender_wait[NUMBER_OF_MEASURES];
	uint32_t sender_send[NUMBER_OF_MEASURES];
	uint32_t receiver_wait[NUMBER_OF_MEASURES];
	uint8_t channels[NUMBER_OF_MEASURES];
	uint8_t modes[NUMBER_OF_MEASURES];
	uint8_t trim[NUMBER_OF_MEASURES];
	uint8_t num_of_measures = 0; //how many measures was configured
	int8_t active_measure = -2;
	bool sender_sends=FALSE, sender_waits=FALSE;
	bool sender[NUMBER_OF_MEASURES]; //TRUE - if the mote is sender during the Ti. measure
	uint32_t message_received_time;

	task void MeasureDone();
	
	event void Boot.booted(){
		call SplitControl.start();
	}
	
	event void SplitControl.startDone(error_t error){
		if( active_measure < 0 ){
			call SetXtalTrim.setNow(0);
			call RadioChannel.setChannel(RFA1_DEF_CHANNEL);
		} else {
			call SetXtalTrim.setNow(trim[active_measure]);
			call RadioChannel.setChannel(channels[active_measure]);
		}
	}

	event void SplitControl.stopDone(error_t error){}
	
	/**LEDS:
	 *LED0 : Waits before receive
	 *LED1 : Waits before sending
	 *LED2 : Sending
	 *LED3 : Receiving
	 */
	
	inline static bool startNextMeasure(bool isRadioOn){
		if( ++active_measure >= num_of_measures )
			active_measure = -2;
		
		if(!isRadioOn) {
			call SplitControl.start();
		} else {
			if( active_measure < 0 ){
				call SetXtalTrim.setNow(0);
				call RadioChannel.setChannel(RFA1_DEF_CHANNEL);
			} else {
				call SetXtalTrim.setNow(trim[active_measure]);
				call RadioChannel.setChannel(channels[active_measure]);
			}
		}
		
		if( active_measure < 0 )
			return FALSE;
		
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
		return TRUE;
	}
	
	async event void Alarm.fired(){
		call Leds.set(0);
		if(sender[active_measure]){ //sender 
			if(sender_sends){
				/*Here to stop sending*/
				call AtmelRadioTest.stopTest();
				//TODO radioStart should be done in the driverlayer and the trimming should be restored here
				/**********************/
				if (!startNextMeasure(FALSE)){
					return;
				}
			}else if(sender_waits){
				call Alarm.startAt(message_received_time,sender_send[active_measure]);	
				sender_sends = TRUE;
				sender_waits = FALSE;	
				call Leds.led2On();
				/*Here to start sending the Continious wave*/
				call AtmelRadioTest.startCWTest(0xff, 0xff,(modes[active_measure]==1)?RFA1_TEST_MODE_CW_PLUS:RFA1_TEST_MODE_CW_MINUS);
				/*******************************************/
			}
		}else{ //receiver
			call Leds.led3On();
			/*Here to start receiving the Continious wave*/
			measureTime[active_measure] = call RssiMonitor.start( buffer[active_measure], BUFFER_LEN);
			/*******************************************/
			call Leds.led3Off();
			
			if (!startNextMeasure(TRUE)){
				post MeasureDone();
				return;
			}
		}
	}

	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
		config_msg_t* msg = (config_msg_t*)payload;
		uint8_t i;
		if(active_measure >= -1)
			return bufPtr;
		if(call PacketTimeStampRadio.isValid(bufPtr)){
			message_received_time = call PacketTimeStampRadio.timestamp(bufPtr);
		} else
			return bufPtr;
		num_of_measures = 0;
		controller = call AMPacket.source(bufPtr);
		for(i=0;i<len/sizeof(config_msg_t);i++){
			if(msg->Tsender_send > 0){ //if > 0 then this measure is configured
				num_of_measures++; //how many measures are configured 
				// 				if(call DiagMsg.record()){
				// 					call DiagMsg.uint8(num_of_measures);
				// 					call DiagMsg.uint16(msg->Tsender1ID);
				// 					call DiagMsg.uint16(msg->Tsender2ID);
				// 					call DiagMsg.uint8(msg->Ttrim1);
				// 					call DiagMsg.uint8(msg->Ttrim2);
				// 					call DiagMsg.uint8(msg->Tchannel);
				// 					call DiagMsg.uint16(msg->Tmode);
				// 					call DiagMsg.uint32(msg->Tsender_wait);
				// 					call DiagMsg.uint32(msg->Tsender_send);
				// 					call DiagMsg.uint32(msg->Treceiver_wait);
				// 					call DiagMsg.send();
				// 				}
				if( TOS_NODE_ID == msg->Tsender1ID || msg->Tsender1ID == 0xffff ) {
					sender[i] = TRUE;
					trim[i] = msg->Ttrim1;
				} else if(TOS_NODE_ID == msg->Tsender2ID){
					sender[i] = TRUE;
					trim[i] = msg->Ttrim2;
				}else{
					sender[i] = FALSE;
					trim[i] = 0;
				}
				channels[i] = msg->Tchannel; //wich channel is used
				modes[i] = msg->Tmode; // + - 0,5MHz
				sender_wait[i] = msg->Tsender_wait; // sender waits before i. sending
				sender_send[i] = msg->Tsender_send; // sender sends Cont. wave 
				receiver_wait[i] = msg->Treceiver_wait;//receiver waits before i. receive
				msg++;	// [i. config] ---> [i+1. config]	
			}else{
				break;
			}
		}	
		active_measure = -1;
		startNextMeasure(TRUE);
		return bufPtr;
	}

	uint8_t currentMeas;
	uint16_t offset;
	
	task void sendData(){
		uint8_t i;
		rssiMessage_t *payload = (rssiMessage_t*)call Packet.getPayload(&messageBuf, sizeof(rssiMessage_t));
		call Leds.led3Toggle();
		payload->index = offset;
		for( i=0; i<MSG_BUF_LEN; i++){
			payload->data[i] = buffer[currentMeas][offset+i];
		}
		call PacketAcknowledgements.requestAck(&messageBuf);
		if( call AMSend.send(controller, &messageBuf, sizeof(rssiMessage_t)) != SUCCESS )
			post sendData();
	}
	
	task void sendNextMeasure(){
		offset = 0;
		currentMeas++;
		while(currentMeas < num_of_measures && sender[currentMeas])
			currentMeas++;
		if( currentMeas < num_of_measures )
			post sendData();
		else
			call Leds.led3Off();
	}
	
	task void sendDone(){
		rssiDataDone_t *payload = (rssiDataDone_t*)call Packet.getPayload(&messageBuf, sizeof(rssiDataDone_t));
		call Leds.led3Toggle();
		payload->time = measureTime[currentMeas];
		call PacketAcknowledgements.requestAck(&messageBuf);
		if( call RssiDone.send(controller, &messageBuf, sizeof(rssiDataDone_t)) != SUCCESS )
			post sendDone();
	}
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if( error == SUCCESS && call PacketAcknowledgements.wasAcked(bufPtr) )
			offset+= MSG_BUF_LEN;
		
		if(offset < BUFFER_LEN){
			post sendData();
		}else {
			post sendDone();
		}
	}
	
	event void RssiDone.sendDone(message_t* bufPtr, error_t error) {
		if( error == SUCCESS && call PacketAcknowledgements.wasAcked(bufPtr) ){
			post sendNextMeasure();
		} else {
			post sendDone();
		}
	}
	
	task void MeasureDone(){
		currentMeas = -1;
		post sendNextMeasure();
	}
	
	
	event void RadioChannel.setChannelDone(){}

}
