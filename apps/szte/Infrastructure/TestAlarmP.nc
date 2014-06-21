#include "TestAlarm.h"


#define NUMBER_OF_INFRAST_NODES 4
#define NUMBER_OF_MEASURES (NUMBER_OF_INFRAST_NODES-2)
#define BUFFER_LEN 500

#define SENDING_TIME 50

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
		SEND_SYNCH=2,
		RECV_SYNCH=3,
		number_of_slots = 16
	};

	typedef struct schedule_t{
		uint8_t work;
	} schedule_t;
	norace schedule_t settings[number_of_slots];

	norace bool wait_to_start=FALSE;
	message_t packet;
	norace uint32_t message_sended_time,message_received_time;
	norace uint8_t active_measure=0;
	norace uint32_t firetime=0;
	uint8_t buffer[number_of_slots][BUFFER_LEN];
	uint32_t SLOT_TIME = 65; //measure slot
	uint32_t SYNCH_SLOT = 30; //between frames
	uint32_t SEND_SLOT = 65000; //between super frames
	norace uint8_t buffer_counter = 0;
	norace bool wait_for_synch = FALSE;
	norace bool synch_received = FALSE;

	task void MeasureDone();
	task void MeasureStart();
	
	event void Boot.booted(){
		call SplitControl.start();
		if(NUMBER_OF_INFRAST_NODES == 4){
			if(TOS_NODE_ID==1){
				settings[0].work=SEND_SYNCH;
				settings[1].work=TX;
				settings[2].work=TX;
				settings[3].work=RX;
				settings[4].work=RECV_SYNCH;
				settings[5].work=TX;
				settings[6].work=TX;
				settings[7].work=RX;
				settings[8].work=RECV_SYNCH;
				settings[9].work=TX;
				settings[10].work=TX;
				settings[11].work=RX;
				settings[12].work=RECV_SYNCH;
				settings[13].work=RX;
				settings[14].work=RX;
				settings[15].work=RX;
				wait_to_start = TRUE; //it will start the action
				call Alarm.startAt(0,(uint32_t)65000);
			}
			if(TOS_NODE_ID==2){
				settings[0].work=RECV_SYNCH;
				settings[1].work=RX;
				settings[2].work=RX;
				settings[3].work=RX;
				settings[4].work=SEND_SYNCH;
				settings[5].work=TX;
				settings[6].work=RX;
				settings[7].work=TX;
				settings[8].work=RECV_SYNCH;
				settings[9].work=TX;
				settings[10].work=RX;
				settings[11].work=TX;
				settings[12].work=RECV_SYNCH;
				settings[13].work=TX;
				settings[14].work=TX;
				settings[15].work=RX;
			}
			if(TOS_NODE_ID==3){
				settings[0].work=RECV_SYNCH;
				settings[1].work=TX;
				settings[2].work=RX;
				settings[3].work=TX;
				settings[4].work=RECV_SYNCH;
				settings[5].work=RX;
				settings[6].work=RX;
				settings[7].work=RX;
				settings[8].work=SEND_SYNCH;
				settings[9].work=RX;
				settings[10].work=TX;
				settings[11].work=TX;
				settings[12].work=RECV_SYNCH;
				settings[13].work=TX;
				settings[14].work=RX;
				settings[15].work=TX;
			}
			if(TOS_NODE_ID==4){
				settings[0].work=RECV_SYNCH;
				settings[1].work=RX;
				settings[2].work=TX;
				settings[3].work=TX;
				settings[4].work=RECV_SYNCH;
				settings[5].work=RX;
				settings[6].work=TX;
				settings[7].work=TX;
				settings[8].work=RECV_SYNCH;
				settings[9].work=RX;
				settings[10].work=RX;
				settings[11].work=RX;
				settings[12].work=SEND_SYNCH;
				settings[13].work=RX;
				settings[14].work=TX;
				settings[15].work=TX;
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
	*All LEDS: between superframes
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
				if(active_measure == number_of_slots){//end of superframe
					call Alarm.stop();
					post MeasureDone();
					return;
				}
				if(wait_for_synch == TRUE && synch_received == FALSE){//did NOT get synch
					if(settings[active_measure+4].work==RECV_SYNCH){//receives synch in the next frame
						return;
					}else{ //sends synch in the next frame
						active_measure += 4; //does nothing
						firetime += 3*SLOT_TIME; //waits until the end of the frame
						call Alarm.startAt(message_received_time,firetime);
						return;	
					}
				}
				if(settings[active_measure].work==RECV_SYNCH){//waits for synch in this frame
					wait_for_synch = TRUE;
					synch_received = FALSE;
					firetime += SYNCH_SLOT;
					call Alarm.startAt(message_received_time,firetime);
					return;					
				}
				if(settings[active_measure].work==TX || settings[active_measure].work==RX){
					firetime += SLOT_TIME;
					call Alarm.startAt(message_received_time,firetime);
				}
				if(settings[active_measure].work==TX){ //sender
					call Leds.led2On();
					call RadioContinuousWave.sendWave(CHANNEL,TRIM1, RFA1_DEF_RFPOWER, SENDING_TIME);
					call Leds.led2Off();
				}else if(settings[active_measure].work==RX){ //receiver
					uint16_t time = 0;
					call Leds.led3On();
					call RadioContinuousWave.sampleRssi(CHANNEL, getBuffer(buffer[buffer_counter]), BUFFER_LEN, &time);
					++buffer_counter%number_of_slots;
					call Leds.led3Off();
				}else if(settings[active_measure].work==SEND_SYNCH){//sends synch in this frame
					uint8_t i;
					sync_message_t* msg = (sync_message_t*)call Packet.getPayload(&packet,sizeof(sync_message_t));
					msg->frame = active_measure/4;
					while(i<255) i=i+1; //receiver must be ready
					call AMSend.send(0xFFFF, &packet, sizeof(sync_message_t));
					call Leds.set(7);
				}
				active_measure = (active_measure+1);
			}
	}

	/*Synch msg sent*/
	event void AMSend.sendDone(message_t* bufPtr, error_t error){
			if(call PacketTimeStampRadio.isValid(bufPtr)){
				call Alarm.stop();
				message_sended_time = call PacketTimeStampRadio.timestamp(bufPtr);
				//this node's "message_received_time" is when it sends the message
				message_received_time = message_sended_time;
				firetime = SYNCH_SLOT;
				call Alarm.startAt(message_received_time,firetime);
			}
	}

	event void RssiDone.sendDone(message_t* bufPtr, error_t error){

	}
	/*Synch msg received*/
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
		sync_message_t* msg = (sync_message_t*)payload;
		if(call PacketTimeStampRadio.isValid(bufPtr)){
			call Alarm.stop();
			message_received_time = call PacketTimeStampRadio.timestamp(bufPtr);
			active_measure = msg->frame*4+1;
			firetime = SYNCH_SLOT;
		    call Alarm.startAt(message_received_time,firetime);
			synch_received = TRUE;
			wait_for_synch = FALSE;
		}
		return bufPtr;
	}

	task void MeasureDone(){ //what to do between super frames
		buffer_counter = 0;
		active_measure = 0;
		firetime += SEND_SLOT;
		call Alarm.startAt(message_received_time,firetime);
		call Leds.set(15);
	}

	task void MeasureStart(){
		sync_message_t* msg = (sync_message_t*)call Packet.getPayload(&packet,sizeof(sync_message_t));
		msg->frame = 0;
		call AMSend.send(0xFFFF, &packet, sizeof(sync_message_t));
		active_measure = 1;
	}

}
