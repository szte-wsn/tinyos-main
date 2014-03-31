#include "TestAlarm.h"

#define NUMBER_OF_MEASURES 3
#define BUFFER_LEN 2000

module TestAlarmP{
	uses interface Boot;
	uses interface SplitControl;
	uses interface Leds;
	
	uses interface Alarm<T62khz, uint32_t> as Alarm;
	uses interface Receive;
	uses interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
	
	uses interface RadioContinuousWave;
	uses interface AMSend;
	uses interface AMSend as RssiDone;
	uses interface AMPacket;
	uses interface Packet;
	uses interface PacketAcknowledgements;
	
	uses interface DiagMsg;
}
implementation{
	typedef nx_struct result_t{
		nx_uint16_t measureTime;
		nx_uint32_t period;
		nx_uint32_t phase;
		//debug only:
		nx_uint8_t channel;
		nx_uint16_t senders[2];
		nx_int8_t fineTunes[2];
		nx_uint8_t power[2];
	} result_t;
	
	typedef struct measurement_setting_t{
		bool isSender:1;
		uint32_t wait;
		uint8_t channel;
		//sender only
		uint16_t sendTime;
		int8_t fineTune;
		uint8_t power;
	} measurement_setting_t;
	
	norace measurement_setting_t settings[NUMBER_OF_MEASURES];
	
	norace uint8_t num_of_measures = 0; //how many measures was configured
	norace int8_t active_measure = -2;
	norace uint32_t message_received_time;
	
	uint8_t buffer[NUMBER_OF_MEASURES][BUFFER_LEN+sizeof(result_t)];
	uint16_t controller;
	message_t messageBuf;
	
	inline static result_t* getResult(uint8_t *buf){
		return (result_t*)buf;
	}
	
	inline static uint8_t* getBuffer(uint8_t *buf){
		return (uint8_t*)(buf + sizeof(result_t));
	}
	
	task void MeasureDone();
	
	event void Boot.booted(){
		call SplitControl.start();
	}
	
	event void SplitControl.startDone(error_t error){}

	event void SplitControl.stopDone(error_t error){}
	
	/**LEDS:
	*LED0 : Waits before receive
	*LED1 : Waits before sending
	*LED2 : Sending
	*LED3 : Receiving
	*/
	
	inline static bool startNextMeasure(){
		if( ++active_measure >= num_of_measures )
			active_measure = -2;
		
		if( active_measure < 0 )
			return FALSE;
		
		call Alarm.startAt(message_received_time,settings[active_measure].wait);
		
		if(settings[active_measure].isSender){
			call Leds.led1On();
		}else{
			call Leds.led0On();
		}
		return TRUE;
	}
	
	async event void Alarm.fired(){
		call Leds.set(0);
		if(settings[active_measure].isSender){ //sender
			call Leds.led2On();
			call RadioContinuousWave.sendWave(settings[active_measure].channel, settings[active_measure].fineTune, settings[active_measure].power, settings[active_measure].sendTime);
			call Leds.led2Off();
		}else{ //receiver
			uint16_t time = 0;
			call Leds.led3On();
			call RadioContinuousWave.sampleRssi(settings[active_measure].channel, getBuffer(buffer[active_measure]), BUFFER_LEN, &time);
			getResult(buffer[active_measure])->measureTime = time;
			call Leds.led3Off();
		}
		if (!startNextMeasure()){
			post MeasureDone();
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
				settings[i].channel = msg->Tchannel; //wich channel is used
				if( TOS_NODE_ID == msg->Tsender1ID || TOS_NODE_ID == msg->Tsender2ID || msg->Tsender1ID == 0xffff ) { //sender only stuff
					settings[i].isSender = TRUE;
					settings[i].wait = msg->Tsender_wait;
					settings[i].sendTime = msg->Tsender_send;
					settings[i].power = RFA1_DEF_RFPOWER; //TODO
					
					if( TOS_NODE_ID == msg->Tsender2ID ){
						settings[i].fineTune = msg->Ttrim2;
					} else {
						settings[i].fineTune = msg->Ttrim2;
					}
				} else { //receiver only stuff
					settings[i].isSender = FALSE;
					settings[i].fineTune = 0;
					settings[i].wait = msg->Treceiver_wait;
					
					//TODO is this needed anything besides debug?
					getResult(buffer[i])->senders[0] = msg->Tsender1ID;
					getResult(buffer[i])->senders[1] = msg->Tsender2ID;
					getResult(buffer[i])->fineTunes[0] = msg->Ttrim1;
					getResult(buffer[i])->fineTunes[1] = msg->Ttrim2;
					getResult(buffer[i])->power[0] = RFA1_DEF_RFPOWER;
					getResult(buffer[i])->power[1] = RFA1_DEF_RFPOWER;
					getResult(buffer[i])->channel = msg->Tchannel;
				}
				
				if(call DiagMsg.record()){
					call DiagMsg.uint8(num_of_measures);
					call DiagMsg.uint16(msg->Tsender1ID);
					call DiagMsg.uint16(msg->Tsender2ID);
					call DiagMsg.uint8(msg->Ttrim1);
					call DiagMsg.uint8(msg->Ttrim2);
					call DiagMsg.uint8(msg->Tchannel);
					call DiagMsg.uint16(msg->Tmode);
					call DiagMsg.uint32(msg->Tsender_wait);
					call DiagMsg.uint32(msg->Tsender_send);
					call DiagMsg.uint32(msg->Treceiver_wait);
					call DiagMsg.send();
				}
				
				msg++;	// [i. config] ---> [i+1. config]	
			}else{
				break;
			}
		}	
		active_measure = -1;
		startNextMeasure();
		return bufPtr;
	}

	
	//TODO If the mote receives a new measure command while sending, it could cause unexpected things. 
	 //But this is not the final downloader, so until that, it has to be used with caution
	 
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
		while(currentMeas < num_of_measures && settings[currentMeas].isSender)
			currentMeas++;
		if( currentMeas < num_of_measures )
			post sendData();
		else
			call Leds.led3Off();
	}
	
	task void sendDone(){
		call Leds.led3Toggle();
		call PacketAcknowledgements.requestAck(&messageBuf);
		if( call RssiDone.send(controller, &messageBuf, sizeof(rssiDataDone_t)) != SUCCESS )
			post sendDone();
	}
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if( error == SUCCESS && call PacketAcknowledgements.wasAcked(bufPtr) )
			offset+= MSG_BUF_LEN;
		
		if(offset < (BUFFER_LEN + sizeof(result_t))){
			if(offset + MSG_BUF_LEN > (BUFFER_LEN + sizeof(result_t)))
				offset = (BUFFER_LEN + sizeof(result_t)) - MSG_BUF_LEN;
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
	
	task void processMeasure(){
		uint8_t i;
		for(i=0;i<num_of_measures;i++){
			getResult(buffer[i])->measureTime = (uint32_t)(getResult(buffer[i])->measureTime)*1e4 / 625;
		}
		//TODO
		post sendNextMeasure();
	}
	
	task void MeasureDone(){
		currentMeas = -1;
		post processMeasure();
	}

}
