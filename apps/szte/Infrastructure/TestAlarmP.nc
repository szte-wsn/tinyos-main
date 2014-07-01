#include "TestAlarm.h"


#define NUMBER_OF_INFRAST_NODES 4
#define NUMBER_OF_MEASURES (NUMBER_OF_INFRAST_NODES-2)
#define BUFFER_LEN 100
#define NUMBER_OF_SLOTS_IN_FRAME 4
#define NUMBER_OF_FRAMES 4

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

	uses interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSend;
	uses interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacket;
	uses interface Receive as SyncReceive;

	uses interface DiagMsg;
	uses interface SplitControl as SerialSplitControl;
}
implementation{

	enum {
		CHANNEL = 11,
		MODE = 0,
		TRIM1 = 17,
		TRIM2 = 0,
		TX = 0,
		RX = 1,
		SEND_SYNC=2,
		RECV_SYNC=3,
		number_of_slots = NUMBER_OF_FRAMES * NUMBER_OF_SLOTS_IN_FRAME
	};

	typedef struct schedule_t{
		uint8_t work;
	} schedule_t;
	norace schedule_t settings[number_of_slots];

	norace bool wait_to_start=TRUE;
	message_t packet;
	norace uint32_t message_sended_time,start_of_frame;
	norace uint8_t active_measure=0;
	norace uint32_t firetime=0;
	uint8_t buffer[number_of_slots][BUFFER_LEN];
	uint32_t MEAS_SLOT = 300; //measure slot
	uint32_t SYNC_SLOT = 300; //between frames
	uint32_t SEND_SLOT = 10000; //between super frames
	norace uint8_t buffer_counter = 0;
	norace bool wait_for_SYNC = FALSE;
	norace bool SYNC_received = FALSE;
	uint8_t cnt = 0;

	task void MeasureDone();
	task void MeasureStart();
	task void SendSync();
	
	event void Boot.booted(){
		call SplitControl.start();
		if(NUMBER_OF_INFRAST_NODES == 4){
			if(TOS_NODE_ID==1){
				settings[0].work=SEND_SYNC;
				settings[1].work=TX;
				settings[2].work=TX;
				settings[3].work=RX;
				settings[4].work=RECV_SYNC;
				settings[5].work=TX;
				settings[6].work=TX;
				settings[7].work=RX;
				settings[8].work=RECV_SYNC;
				settings[9].work=TX;
				settings[10].work=TX;
				settings[11].work=RX;
				settings[12].work=RECV_SYNC;
				settings[13].work=RX;
				settings[14].work=RX;
				settings[15].work=RX;
				firetime = 62000;
				call Alarm.startAt(0,firetime);
			}
			if(TOS_NODE_ID==2){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=RX;
				settings[3].work=RX;
				settings[4].work=SEND_SYNC;
				settings[5].work=TX;
				settings[6].work=RX;
				settings[7].work=TX;
				settings[8].work=RECV_SYNC;
				settings[9].work=TX;
				settings[10].work=RX;
				settings[11].work=TX;
				settings[12].work=RECV_SYNC;
				settings[13].work=TX;
				settings[14].work=TX;
				settings[15].work=RX;
			}
			if(TOS_NODE_ID==3){
				settings[0].work=RECV_SYNC;
				settings[1].work=TX;
				settings[2].work=RX;
				settings[3].work=TX;
				settings[4].work=RECV_SYNC;
				settings[5].work=RX;
				settings[6].work=RX;
				settings[7].work=RX;
				settings[8].work=SEND_SYNC;
				settings[9].work=RX;
				settings[10].work=TX;
				settings[11].work=TX;
				settings[12].work=RECV_SYNC;
				settings[13].work=TX;
				settings[14].work=RX;
				settings[15].work=TX;
			}
			if(TOS_NODE_ID==4){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=TX;
				settings[3].work=TX;
				settings[4].work=RECV_SYNC;
				settings[5].work=RX;
				settings[6].work=TX;
				settings[7].work=TX;
				settings[8].work=RECV_SYNC;
				settings[9].work=RX;
				settings[10].work=RX;
				settings[11].work=RX;
				settings[12].work=SEND_SYNC;
				settings[13].work=RX;
				settings[14].work=TX;
				settings[15].work=TX;
			}
		}
	}
	
	event void SplitControl.startDone(error_t error){}

	event void SplitControl.stopDone(error_t error){
		call SplitControl.start();	
	}
	
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
				if(settings[active_measure].work==RECV_SYNC){//waits for SYNC in this frame
					firetime = SYNC_SLOT;
					start_of_frame = start_of_frame+(NUMBER_OF_SLOTS_IN_FRAME-1)*MEAS_SLOT+SYNC_SLOT;
					call Alarm.startAt(start_of_frame,firetime);
					active_measure++;
					return;					
				}
				if(settings[active_measure].work==TX || settings[active_measure].work==RX){
					firetime += MEAS_SLOT;
					call Alarm.startAt(start_of_frame,firetime);
				}
				if(settings[active_measure].work==TX){ //sender
					//call Leds.led2On();
					call RadioContinuousWave.sendWave(CHANNEL,TRIM1, RFA1_DEF_RFPOWER, SENDING_TIME);
					//call Leds.led2Off();
				}else if(settings[active_measure].work==RX){ //receiver
					uint16_t time = 0;
					//call Leds.led3On();
					call RadioContinuousWave.sampleRssi(CHANNEL, getBuffer(buffer[buffer_counter]), BUFFER_LEN, &time);
					buffer_counter = (buffer_counter+1)%number_of_slots;
					//call Leds.led3Off();
				}else if(settings[active_measure].work==SEND_SYNC){//sends SYNC in this frame
					post SendSync();
				}
				active_measure++;
			}
			if(call DiagMsg.record()){
				call DiagMsg.str("AS:");
				call DiagMsg.uint8(active_measure-1);
				/*call DiagMsg.str("");
				call DiagMsg.uint8(buffer_counter);
				/*call DiagMsg.str("");
				call DiagMsg.uint32(start_of_frame);*/
				call DiagMsg.send();
			}
	}

	task void SendSync(){
		error_t ret;
		sync_message_t* msg = (sync_message_t*)call TimeSyncAMSend.getPayload(&packet,sizeof(sync_message_t));
		msg->frame = active_measure/4;	
		//while(i<1000000) i=(i+1); //receiver must be ready
		start_of_frame = start_of_frame+(NUMBER_OF_SLOTS_IN_FRAME-1)*MEAS_SLOT+SYNC_SLOT;
		firetime = SYNC_SLOT;
		call Alarm.startAt(start_of_frame,firetime);
		ret = call TimeSyncAMSend.send(0xFFFF, &packet, sizeof(sync_message_t), start_of_frame);
			if(call DiagMsg.record()){
				call DiagMsg.str("SR:");
				call DiagMsg.uint8((uint8_t)ret);
				/*call DiagMsg.str(" AS:");
				call DiagMsg.uint8(active_measure);*/
				call DiagMsg.send();
			}	
		call Leds.led0Toggle();
		return;
	}

	/*SYNC msg sent*/
	event void AMSend.sendDone(message_t* bufPtr, error_t error){
			/*if(call PacketTimeStampRadio.isValid(bufPtr)){
				call Alarm.stop();
				message_sended_time = call PacketTimeStampRadio.timestamp(bufPtr);
				//this node's "start_of_frame" is when it sends the message
				start_of_frame = message_sended_time;
				firetime = SYNC_SLOT;
				call Alarm.startAt(start_of_frame,firetime);
			}*/
	}
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
		/*sync_message_t* msg = (sync_message_t*)payload;
		if(call TimeSyncPacket.isValid(bufPtr)){
			call Alarm.stop();
			start_of_frame = call TimeSyncPacket.eventTime(bufPtr);
			active_measure = msg->frame*4+1;
			firetime = SYNC_SLOT;
		    call Alarm.startAt(start_of_frame,firetime);
		}*/
		return bufPtr;
	}

	event void RssiDone.sendDone(message_t* bufPtr, error_t error){
		
	}

	/*SYNC msg received*/
	event message_t* SyncReceive.receive(message_t* bufPtr, void* payload, uint8_t len){
		sync_message_t* msg = (sync_message_t*)payload;
		if(call TimeSyncPacket.isValid(bufPtr)){
			//call Leds.led2Toggle();
			call Alarm.stop();
			start_of_frame = call TimeSyncPacket.eventTime(bufPtr);
			active_measure = msg->frame*4+1;
			firetime = SYNC_SLOT;
		    call Alarm.startAt(start_of_frame,firetime);
		}
		return bufPtr;
	}


	event void TimeSyncAMSend.sendDone(message_t* msg, error_t error){
			if(call DiagMsg.record()){
				call DiagMsg.str("SD:");
				call DiagMsg.uint8((uint8_t)error);
				call DiagMsg.send();
			}
	}

	task void MeasureDone(){ //what to do between super frames
		buffer_counter = 0;
		active_measure = 0;
		firetime += SEND_SLOT;
		call Alarm.startAt(start_of_frame,firetime);
		start_of_frame = start_of_frame + SEND_SLOT;
		if(call DiagMsg.record()){
				call DiagMsg.str("*");
				call DiagMsg.send();
			}
		//call Leds.set(15);
	}

	task void MeasureStart(){
		sync_message_t* msg = (sync_message_t*)call Packet.getPayload(&packet,sizeof(sync_message_t));
		msg->frame = 0;
		start_of_frame = firetime;  //62000
		call TimeSyncAMSend.send(0xFFFF, &packet, sizeof(sync_message_t),start_of_frame);
		firetime = SYNC_SLOT;
		call Alarm.startAt(start_of_frame,firetime);
		active_measure = 1;
	}

	event void SerialSplitControl.startDone(error_t error){
		
	}

	event void SerialSplitControl.stopDone(error_t error){
		
	}

}
