#include "TestAlarm.h"

module TestAlarmP{
	uses interface Boot;
	uses interface SplitControl;
	uses interface Leds;
	
	uses interface Alarm<T62khz, uint32_t> as Alarm;
	uses interface Receive;
	uses interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
	
	uses interface RadioContinuousWave;
	
	uses interface StdControl;
	uses interface Storage;
	
	uses interface MeasureWave;
	
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
		call StdControl.stop();
		num_of_measures = 0;
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
	
	task void processMeasure(){
		uint8_t i;
		for(i=0;i<num_of_measures;i++){
			if( !settings[i].isSender ){
// 				uint8_t temp[BUFFER_LEN];
// 				uint8_t zeroPoint;
// 				uint16_t startPoint;
// 				#define AMPLITUDE_THRESHOLD 2
// 				#define TIME_THRESHOLD 10
// 				#define START_OFFSET 16
// 				startPoint = call MeasureWave.getStart(getBuffer(buffer[i]), BUFFER_LEN, AMPLITUDE_THRESHOLD, TIME_THRESHOLD);
// 				memcpy(temp, getBuffer(buffer[i]), BUFFER_LEN);
// 				call MeasureWave.filter(temp, BUFFER_LEN, 3, 2);
// 				getResult(buffer[i])->period = call MeasureWave.getPeriod(temp+startPoint+START_OFFSET, BUFFER_LEN-startPoint-START_OFFSET, &zeroPoint);
// 				getResult(buffer[i])->phase = call MeasureWave.getPhase(temp+startPoint, BUFFER_LEN-startPoint, START_OFFSET, getResult(buffer[i])->period, zeroPoint);
// 				
// 				if( call DiagMsg.record() ){
// 					call DiagMsg.str("D T");
// 					call DiagMsg.uint16(startPoint);
// 					call DiagMsg.uint8(zeroPoint);
// 					call DiagMsg.uint16(getResult(buffer[i])->period);
// 					call DiagMsg.uint16(getResult(buffer[i])->phase);
// 					call DiagMsg.send();
// 				}
// 				
// 				//convert everything to us
				getResult(buffer[i])->measureTime = call RadioContinuousWave.convertTime(getResult(buffer[i])->measureTime);
				getResult(buffer[i])->period = ((uint32_t)getResult(buffer[i])->period * getResult(buffer[i])->measureTime)/BUFFER_LEN;
				getResult(buffer[i])->phase = ((uint32_t)getResult(buffer[i])->phase * getResult(buffer[i])->measureTime)/BUFFER_LEN;
// 				if( call DiagMsg.record() ){
// 					call DiagMsg.str("D us");
// 					call DiagMsg.uint16(startPoint);
// 					call DiagMsg.uint8(zeroPoint);
// 					call DiagMsg.uint16(getResult(buffer[i])->period);
// 					call DiagMsg.uint16(getResult(buffer[i])-NUMBER_OF_MEASURES>phase);
// 					call DiagMsg.send();
// 				}
				call Storage.store(buffer[i]);
			}
		}
		call StdControl.start();
	}
	
	task void MeasureDone(){
		//currentMeas = -1;
		post processMeasure();
	}

}
