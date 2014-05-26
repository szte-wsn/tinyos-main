#include "TestAlarm.h"


#define NUMBER_OF_INFRAST_NODES 4
#define NUMBER_OF_MEASURES (NUMBER_OF_INFRAST_NODES-2)
#define BUFFER_LEN 500

#define SENDING_TIME 50000

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

	enum {
		CHANNEL = 11,
		MODE = 0,
		TRIM1 = 17,
		TRIM2 = 0,
		TX = 0,
		RX = 1,
		SENDS_DATA=2,
		EMPTY_SLOT=3,
		number_of_frames = 16
	};
	/*typedef struct measurement_setting_t{
		bool isSender:1;
		uint8_t channel;
		int8_t fineTune;
		uint8_t power;
	} measurement_setting_t;
	norace measurement_setting_t settings[8];*/

	typedef struct schedule_t{
		uint8_t work:2;
	} schedule_t;
	norace schedule_t settings[number_of_frames];

	bool wait_to_start=FALSE;
	message_t packet;
	uint32_t message_sended_time,message_received_time;
	uint8_t active_measure=0;
	uint32_t firetime=0;
	uint8_t buffer[12][BUFFER_LEN];
	uint32_t SLOT_TIME=100000;
	uint8_t buffer_counter = 0;

	task void MeasureDone();
	task void MeasureStart();
	
	event void Boot.booted(){
		call SplitControl.start();
		if(NUMBER_OF_INFRAST_NODES == 4){
			if(TOS_NODE_ID==1){
				settings[0].work=TX;
				settings[1].work=TX;
				settings[2].work=RX;
				settings[3].work=EMPTY_SLOT;
				settings[4].work=TX;
				settings[5].work=TX;
				settings[6].work=RX;
				settings[7].work=EMPTY_SLOT;
				settings[8].work=TX;
				settings[9].work=TX;
				settings[10].work=RX;
				settings[11].work=EMPTY_SLOT;
				settings[12].work=RX;
				settings[13].work=RX;
				settings[14].work=RX;
				settings[15].work=SENDS_DATA;
				wait_to_start = TRUE;
				call Alarm.startAt(0,(uint32_t)65000);
			}
			if(TOS_NODE_ID==2){
				settings[0].work=RX;
				settings[1].work=RX;
				settings[2].work=RX;
				settings[3].work=SENDS_DATA;
				settings[4].work=TX;
				settings[5].work=RX;
				settings[6].work=TX;
				settings[7].work=EMPTY_SLOT;
				settings[8].work=TX;
				settings[9].work=RX;
				settings[10].work=TX;
				settings[11].work=EMPTY_SLOT;
				settings[12].work=TX;
				settings[13].work=TX;
				settings[14].work=RX;
				settings[15].work=EMPTY_SLOT;
			}
			if(TOS_NODE_ID==3){
				settings[0].work=TX;
				settings[1].work=RX;
				settings[2].work=TX;
				settings[3].work=EMPTY_SLOT;
				settings[4].work=RX;
				settings[5].work=RX;
				settings[6].work=RX;
				settings[7].work=SENDS_DATA;
				settings[8].work=RX;
				settings[9].work=TX;
				settings[10].work=TX;
				settings[11].work=EMPTY_SLOT;
				settings[12].work=TX;
				settings[13].work=RX;
				settings[14].work=TX;
				settings[15].work=EMPTY_SLOT;
			}
			if(TOS_NODE_ID==4){
				settings[0].work=RX;
				settings[1].work=TX;
				settings[2].work=TX;
				settings[3].work=EMPTY_SLOT;
				settings[4].work=RX;
				settings[5].work=TX;
				settings[6].work=TX;
				settings[7].work=EMPTY_SLOT;
				settings[8].work=RX;
				settings[9].work=RX;
				settings[10].work=RX;
				settings[11].work=SENDS_DATA;
				settings[12].work=RX;
				settings[13].work=TX;
				settings[14].work=TX;
				settings[15].work=EMPTY_SLOT;
			}
		}
	}
	
	event void SplitControl.startDone(error_t error){}

	event void SplitControl.stopDone(error_t error){}
	
	/**LEDS:
	*LED0 : Waits before receive
	*LED1 : Waits before sending
	*LED2 : Sending
	*LED3 : Receiving
	*/
	
	inline static uint8_t* getBuffer(uint8_t *buf){
		return (uint8_t*)(buf);
	}
	
	async event void Alarm.fired(){
			if(wait_to_start){ //start the action
				post MeasureStart();
				wait_to_start = FALSE;
			}else{ //measure
				call Leds.set(0);
				if(active_measure<number_of_frames){
					if(active_measure<number_of_frames-1){
						call Alarm.startAt(message_received_time,SLOT_TIME);
						message_received_time+=SLOT_TIME;
					}
					active_measure++;
				}else{
					call Alarm.stop();
					post MeasureDone();
				} 
				if(settings[active_measure-1].work==TX){ //sender
					call Leds.led2On();
					call RadioContinuousWave.sendWave(CHANNEL,TRIM1, RFA1_DEF_RFPOWER, SENDING_TIME);
					call Leds.led2Off();
				}else if(settings[active_measure-1].work==RX){ //receiver
					uint16_t time = 0;
					call Leds.led3On();
					call RadioContinuousWave.sampleRssi(CHANNEL, getBuffer(buffer[buffer_counter]), BUFFER_LEN, &time);
					buffer_counter++;
					call Leds.led3Off();
				}else if(settings[active_measure-1].work==SENDS_DATA){
					sync_message_t* msg = (sync_message_t*)call Packet.getPayload(&packet,sizeof(sync_message_t));
					call AMSend.send(0xFFFF, &packet, sizeof(sync_message_t));
					call Leds.set(15);
				}
			}
	}


	event void AMSend.sendDone(message_t* bufPtr, error_t error){
			if(call PacketTimeStampRadio.isValid(bufPtr) && TOS_NODE_ID==1){
				call Alarm.stop();
				message_sended_time = call PacketTimeStampRadio.timestamp(bufPtr);
				//this node's "message_received_time" is when it sends the message
				message_received_time = message_sended_time;
				
				call Alarm.startAt(message_received_time,SLOT_TIME);
				message_received_time+=SLOT_TIME;
			}
	}

	event void RssiDone.sendDone(message_t* bufPtr, error_t error){

	}

	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
		sync_message_t* msg = (sync_message_t*)payload;
		if(call PacketTimeStampRadio.isValid(bufPtr)){
			call Alarm.stop();
			message_received_time = call PacketTimeStampRadio.timestamp(bufPtr);
			
		    call Alarm.startAt(message_received_time,SLOT_TIME);
			message_received_time+=SLOT_TIME;
		} else
			return bufPtr;
		return bufPtr;
	}

	task void MeasureDone(){
		buffer_counter = 0;
		active_measure = 0;
		call Leds.set(7);
	}

	task void MeasureStart(){
		sync_message_t* msg = (sync_message_t*)call Packet.getPayload(&packet,sizeof(sync_message_t));
		call AMSend.send(0xFFFF, &packet, sizeof(sync_message_t));
	}


}
