#include "TestAlarm.h"


#define NUMBER_OF_INFRAST_NODES 4
#define BUFFER_LEN 400
#define NUMBER_OF_SLOT_IN_FRAME 4
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
	uses interface PhaseFreqCounter;
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
		NUMBER_OF_SLOTS = NUMBER_OF_FRAMES * NUMBER_OF_SLOT_IN_FRAME,
		MEAS_SLOT = 62, //measure slot
		SYNC_SLOT = 100, //between frames
		SEND_SLOT = 5000 //between super frames
	};

	typedef struct schedule_t{
		uint8_t work;
	} schedule_t;
	norace schedule_t settings[NUMBER_OF_SLOTS];

	norace 	bool 		waitToStart=TRUE;
			message_t 	packet;
	norace 	uint32_t 	message_sended_time,startOfFrame;
	norace 	uint8_t 	activeMeasure=0;
	norace 	uint32_t 	firetime=0;
			uint8_t 	buffer[NUMBER_OF_SLOTS][BUFFER_LEN];
	norace 	uint8_t 	bufferCounter = 0;
			uint8_t 	cnt = 0;

	task void measureDone();
	task void measureStart();
	task void sendSync();
	
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
				activeMeasure = 1;
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
				activeMeasure = 1;
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
				activeMeasure = 1;
			}
		}
	}
	
	event void SplitControl.startDone(error_t error){}

	event void SplitControl.stopDone(error_t error){
		call SplitControl.start();	
	}
	
	inline static uint8_t* getBuffer(uint8_t *buf){
		return (uint8_t*)(buf);
	}
	
	async event void Alarm.fired(){
			if(waitToStart){ //start the action
				post measureStart();
				waitToStart = FALSE;
			}else{ //measure
				if(activeMeasure == NUMBER_OF_SLOTS){//end of superframe
					call Alarm.stop();
					post measureDone();
					return;
				}
				if(settings[activeMeasure].work==RECV_SYNC){//waits for SYNC in this frame
					firetime = SYNC_SLOT;
					startOfFrame = startOfFrame+(NUMBER_OF_SLOT_IN_FRAME-1)*MEAS_SLOT+SYNC_SLOT;
					call Alarm.startAt(startOfFrame,firetime);
					activeMeasure++;
					return;					
				}
				if(settings[activeMeasure].work==TX || settings[activeMeasure].work==RX){
					firetime += MEAS_SLOT;
					call Alarm.startAt(startOfFrame,firetime);
				}
				if(settings[activeMeasure].work==TX){ //sender
					call RadioContinuousWave.sendWave(CHANNEL,TRIM1, RFA1_DEF_RFPOWER, SENDING_TIME);
					//call PhaseFreqCounter.startCounter(getBuffer(buffer[bufferCounter]),BUFFER_LEN);
				}else if(settings[activeMeasure].work==RX){ //receiver
					uint16_t time = 0;
					call RadioContinuousWave.sampleRssi(CHANNEL, getBuffer(buffer[bufferCounter]), BUFFER_LEN, &time);
					bufferCounter = (bufferCounter+1)%NUMBER_OF_SLOTS;
				}else if(settings[activeMeasure].work==SEND_SYNC){//sends SYNC in this frame
					post sendSync();
				}
				//activeMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
				activeMeasure++;
			}
			/*if(call DiagMsg.record()){
				call DiagMsg.str("AS:");
				call DiagMsg.uint8(activeMeasure-1);
				/*call DiagMsg.str("");
				call DiagMsg.uint8(bufferCounter);
				call DiagMsg.str("");
				call DiagMsg.uint32(startOfFrame);
				call DiagMsg.send();
			}*/
	}

	task void sendSync(){
		error_t ret;
		uint8_t mphase, mfreq;
		sync_message_t* msg = (sync_message_t*)call TimeSyncAMSend.getPayload(&packet,sizeof(sync_message_t));
		msg->frame = activeMeasure/4;
		//call PhaseFreqCounter.getPhaseAndFreq(&mphase, &mfreq);
		msg->freq = mfreq;
		msg->phase = mphase;
		startOfFrame = startOfFrame+(NUMBER_OF_SLOT_IN_FRAME-1)*MEAS_SLOT+SYNC_SLOT;
		firetime = SYNC_SLOT;
		call Alarm.startAt(startOfFrame,firetime);
		ret = call TimeSyncAMSend.send(0xFFFF, &packet, sizeof(sync_message_t), startOfFrame);
		return;
	}

	event void PhaseFreqCounter.counterDone(){}

	/*SYNC msg sent*/
	event void AMSend.sendDone(message_t* bufPtr, error_t error){

	}
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){

		return bufPtr;
	}

	event void RssiDone.sendDone(message_t* bufPtr, error_t error){
		
	}

	/*SYNC msg received*/
	event message_t* SyncReceive.receive(message_t* bufPtr, void* payload, uint8_t len){
		sync_message_t* msg = (sync_message_t*)payload;
		if(call TimeSyncPacket.isValid(bufPtr)){
			//call Alarm.stop();
			if(msg->frame*4+1 == activeMeasure){
				startOfFrame = call TimeSyncPacket.eventTime(bufPtr);
				//activeMeasure = msg->frame*4+1;
				firetime = SYNC_SLOT;
				if(call DiagMsg.record()){
					call DiagMsg.str("s");
					call DiagMsg.send();
				}
				if(waitToStart){
		    		call Alarm.startAt(startOfFrame,firetime);
					waitToStart = FALSE;
				}
			}else{
				if(call DiagMsg.record()){
					call DiagMsg.uint8(msg->frame*4+1);
					call DiagMsg.uint8(activeMeasure);
					call DiagMsg.send();
				}
			}
			
		}
		return bufPtr;
	}


	event void TimeSyncAMSend.sendDone(message_t* msg, error_t error){

	}

	task void measureDone(){ //what to do between super frames
		bufferCounter = 0;
		activeMeasure = 0;
		firetime += SEND_SLOT;
		call Alarm.startAt(startOfFrame,firetime);
		startOfFrame = startOfFrame + SEND_SLOT;
		if(call DiagMsg.record()){
				call DiagMsg.str("*");
				call DiagMsg.send();
			}
		call Leds.led3Toggle();
	}

	task void measureStart(){
		sync_message_t* msg = (sync_message_t*)call Packet.getPayload(&packet,sizeof(sync_message_t));
		msg->frame = 0;
		startOfFrame = firetime;  //62000
		call TimeSyncAMSend.send(0xFFFF, &packet, sizeof(sync_message_t),startOfFrame);
		firetime = SYNC_SLOT;
		call Alarm.startAt(startOfFrame,firetime);
		activeMeasure = 1;
	}

	event void SerialSplitControl.startDone(error_t error){
		
	}

	event void SerialSplitControl.stopDone(error_t error){
		
	}

}
