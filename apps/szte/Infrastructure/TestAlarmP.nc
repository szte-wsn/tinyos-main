/* Scheduler

	One measure = SLOT (sendWabe or sampleRSSI)
	The set of slots = FRAME (1 sync/frame)
	The set of frames = SUPERFRAME

*/

#include "TestAlarm.h"


#define NUMBER_OF_INFRAST_NODES 4
#define NUMBER_OF_FRAMES 4
#define NUMBER_OF_SLOT_IN_FRAME 13
#define SENDING_TIME 50
#define BUFFER_LEN 400

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
		TX = 0, //sendWave
		RX = 1, //sampleRSSI
		SEND_SYNC=2, //sends sync message
		RECV_SYNC=3, //waits for sync message
		NUMBER_OF_SLOTS = NUMBER_OF_SLOT_IN_FRAME*NUMBER_OF_FRAMES,
		MEAS_SLOT = 62, //measure slot
		SYNC_SLOT = 400, //between frames
		SEND_SLOT = 620, //between super frames
		BUFFER_SIZE = 10 //size of the buffer
	};

	typedef	struct 	schedule_t{
			uint8_t work;
	}schedule_t;

	norace 	schedule_t 	settings[NUMBER_OF_SLOTS];
	norace 	bool 		waitToStart=TRUE;
			message_t 	packet;
	norace 	uint32_t 	startOfFrame;
	norace 	uint8_t 	activeMeasure=0;
	norace 	uint32_t 	firetime=0;
			uint8_t 	buffer[BUFFER_SIZE][BUFFER_LEN];
	norace 	uint8_t 	bufferCounter = 0;
			uint8_t		cnt=0;
	task 	void 		measureDone();
	task 	void 		measureStart();
	task 	void 		sendSync();
	
	event void Boot.booted(){
		call SplitControl.start();
		if(NUMBER_OF_INFRAST_NODES == 4){
			if(TOS_NODE_ID==1){
				settings[0].work=SEND_SYNC;
				settings[1].work=TX;
				settings[2].work=TX;
				settings[3].work=RX;
				settings[4].work=TX;
				settings[5].work=TX;
				settings[6].work=RX;
				settings[7].work=TX;
				settings[8].work=TX;
				settings[9].work=RX;
				settings[10].work=RX;
				settings[11].work=RX;
				settings[12].work=RX;
				settings[13].work=RECV_SYNC;
				settings[14].work=TX;
				settings[15].work=TX;
				settings[16].work=RX;
				settings[17].work=TX;
				settings[18].work=TX;
				settings[19].work=RX;
				settings[20].work=TX;
				settings[21].work=TX;
				settings[22].work=RX;
				settings[23].work=RX;
				settings[24].work=RX;
				settings[25].work=RX;
				settings[26].work=RECV_SYNC;
				settings[27].work=TX;
				settings[28].work=TX;
				settings[29].work=RX;
				settings[30].work=TX;
				settings[31].work=TX;
				settings[32].work=RX;
				settings[33].work=TX;
				settings[34].work=TX;
				settings[35].work=RX;
				settings[36].work=RX;
				settings[37].work=RX;
				settings[38].work=RX;
				settings[39].work=RECV_SYNC;
				settings[40].work=TX;
				settings[41].work=TX;
				settings[42].work=RX;
				settings[43].work=TX;
				settings[44].work=TX;
				settings[45].work=RX;
				settings[46].work=TX;
				settings[47].work=TX;
				settings[48].work=RX;
				settings[49].work=RX;
				settings[50].work=RX;
				settings[51].work=RX;
				firetime = 62000;
				call Alarm.startAt(0,firetime);
			}
			if(TOS_NODE_ID==2){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=RX;
				settings[3].work=RX;
				settings[4].work=TX;
				settings[5].work=RX;
				settings[6].work=TX;
				settings[7].work=TX;
				settings[8].work=RX;
				settings[9].work=TX;
				settings[10].work=TX;
				settings[11].work=TX;
				settings[12].work=RX;
				settings[13].work=SEND_SYNC;
				settings[14].work=RX;
				settings[15].work=RX;
				settings[16].work=RX;
				settings[17].work=TX;
				settings[18].work=RX;
				settings[19].work=TX;
				settings[20].work=TX;
				settings[21].work=RX;
				settings[22].work=TX;
				settings[23].work=TX;
				settings[24].work=TX;
				settings[25].work=RX;
				settings[26].work=RECV_SYNC;
				settings[27].work=RX;
				settings[28].work=RX;
				settings[29].work=RX;
				settings[30].work=TX;
				settings[31].work=RX;
				settings[32].work=TX;
				settings[33].work=TX;
				settings[34].work=RX;
				settings[35].work=TX;
				settings[36].work=TX;
				settings[37].work=TX;
				settings[38].work=RX;
				settings[39].work=RECV_SYNC;
				settings[40].work=RX;
				settings[41].work=RX;
				settings[42].work=RX;
				settings[43].work=TX;
				settings[44].work=RX;
				settings[45].work=TX;
				settings[46].work=TX;
				settings[47].work=RX;
				settings[48].work=TX;
				settings[49].work=TX;
				settings[50].work=TX;
				settings[51].work=RX;
				activeMeasure = 1;
			}
			if(TOS_NODE_ID==3){
				settings[0].work=RECV_SYNC;
				settings[1].work=TX;
				settings[2].work=RX;
				settings[3].work=TX;
				settings[4].work=RX;
				settings[5].work=RX;
				settings[6].work=RX;
				settings[7].work=RX;
				settings[8].work=TX;
				settings[9].work=TX;
				settings[10].work=TX;
				settings[11].work=RX;
				settings[12].work=TX;
				settings[13].work=RECV_SYNC;
				settings[14].work=TX;
				settings[15].work=RX;
				settings[16].work=TX;
				settings[17].work=RX;
				settings[18].work=RX;
				settings[19].work=RX;
				settings[20].work=RX;
				settings[21].work=TX;
				settings[22].work=TX;
				settings[23].work=TX;
				settings[24].work=RX;
				settings[25].work=TX;
				settings[26].work=SEND_SYNC;
				settings[27].work=TX;
				settings[28].work=RX;
				settings[29].work=TX;
				settings[30].work=RX;
				settings[31].work=RX;
				settings[32].work=RX;
				settings[33].work=RX;
				settings[34].work=TX;
				settings[35].work=TX;
				settings[36].work=TX;
				settings[37].work=RX;
				settings[38].work=TX;
				settings[39].work=RECV_SYNC;
				settings[40].work=TX;
				settings[41].work=RX;
				settings[42].work=TX;
				settings[43].work=RX;
				settings[44].work=RX;
				settings[45].work=RX;
				settings[46].work=RX;
				settings[47].work=TX;
				settings[48].work=TX;
				settings[49].work=TX;
				settings[50].work=RX;
				settings[51].work=TX;
				activeMeasure = 1;
			}
			if(TOS_NODE_ID==4){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=TX;
				settings[3].work=TX;
				settings[4].work=RX;
				settings[5].work=TX;
				settings[6].work=TX;
				settings[7].work=RX;
				settings[8].work=RX;
				settings[9].work=RX;
				settings[10].work=RX;
				settings[11].work=TX;
				settings[12].work=TX;
				settings[13].work=RECV_SYNC;
				settings[14].work=RX;
				settings[15].work=TX;
				settings[16].work=TX;
				settings[17].work=RX;
				settings[18].work=TX;
				settings[19].work=TX;
				settings[20].work=RX;
				settings[21].work=RX;
				settings[22].work=RX;
				settings[23].work=RX;
				settings[24].work=TX;
				settings[25].work=TX;
				settings[26].work=RECV_SYNC;
				settings[27].work=RX;
				settings[28].work=TX;
				settings[29].work=TX;
				settings[30].work=RX;
				settings[31].work=TX;
				settings[32].work=TX;
				settings[33].work=RX;
				settings[34].work=RX;
				settings[35].work=RX;
				settings[36].work=RX;
				settings[37].work=TX;
				settings[38].work=TX;
				settings[39].work=SEND_SYNC;
				settings[40].work=RX;
				settings[41].work=TX;
				settings[42].work=TX;
				settings[43].work=RX;
				settings[44].work=TX;
				settings[45].work=TX;
				settings[46].work=RX;
				settings[47].work=RX;
				settings[48].work=RX;
				settings[49].work=RX;
				settings[50].work=TX;
				settings[51].work=TX;
				activeMeasure = 1;
			}
		}
	}
	
	event void SplitControl.startDone(error_t error){}

	event void SplitControl.stopDone(error_t error){}
	
	inline static uint8_t* getBuffer(uint8_t *buf){
		return (uint8_t*)(buf);
	}
	
	/*if it's not required to do something between the superframes:
			- comment: 		if(activeMeasure == NUMBER_OF_SLOTS){//end of superframe
								call Alarm.stop();
								post measureDone();
								return;
							}
			- comment: 		activeMeasure++;
			- uncomment:	activeMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
	*/

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
					bufferCounter = (bufferCounter+1)%BUFFER_SIZE;
				}else if(settings[activeMeasure].work==SEND_SYNC){//sends SYNC in this frame
					post sendSync();
				}
				//activeMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
				activeMeasure++;
			} 
	}
	/*
		Sends sync message.
	*/
	task void sendSync(){
		//uint8_t mphase, mfreq;
		sync_message_t* msg = (sync_message_t*)call TimeSyncAMSend.getPayload(&packet,sizeof(sync_message_t));
		msg->frame = activeMeasure;
		//call PhaseFreqCounter.getPhaseAndFreq(&mphase, &mfreq);
		//msg->freq = mfreq;
		//msg->phase = mphase;
		startOfFrame = startOfFrame+(NUMBER_OF_SLOT_IN_FRAME-1)*MEAS_SLOT+SYNC_SLOT;
		firetime = SYNC_SLOT;
		call Alarm.startAt(startOfFrame,firetime);
		call TimeSyncAMSend.send(0xFFFF, &packet, sizeof(sync_message_t), startOfFrame);
		return;
	}
	/*Counting is done*/
	event void PhaseFreqCounter.counterDone(){}

	event void AMSend.sendDone(message_t* bufPtr, error_t error){}
	
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
		return bufPtr;
	}

	event void RssiDone.sendDone(message_t* bufPtr, error_t error){}

	/*
		SYNC msg received
	*/
	event message_t* SyncReceive.receive(message_t* bufPtr, void* payload, uint8_t len){
		sync_message_t* msg = (sync_message_t*)payload;
		if(call TimeSyncPacket.isValid(bufPtr)){
			if(msg->frame == activeMeasure){
				startOfFrame = call TimeSyncPacket.eventTime(bufPtr);
				firetime = SYNC_SLOT;
				if(waitToStart){
		    		call Alarm.startAt(startOfFrame,firetime);
					waitToStart = FALSE;
				}
			}
		}
		return bufPtr;
	}

	/*
		Sync message sent
	*/
	event void TimeSyncAMSend.sendDone(message_t* msg, error_t error){

	}
	/*
		What to do between super frames.
	*/
	task void measureDone(){
		bufferCounter = 0;
		activeMeasure = 0;
		firetime += SEND_SLOT;
		call Alarm.startAt(startOfFrame,firetime);
		startOfFrame = startOfFrame + SEND_SLOT;
		if(++cnt == 10){
			call Leds.led3Toggle();
			cnt=0;
		}
	}
	/*
		Start the action.
	*/
	task void measureStart(){
		sync_message_t* msg = (sync_message_t*)call Packet.getPayload(&packet,sizeof(sync_message_t));
		msg->frame = 1;
		startOfFrame = firetime;  //62000
		call TimeSyncAMSend.send(0xFFFF, &packet, sizeof(sync_message_t),startOfFrame);
		firetime = SYNC_SLOT;
		call Alarm.startAt(startOfFrame,firetime);
		activeMeasure = 1;
	}

	event void SerialSplitControl.startDone(error_t error){}

	event void SerialSplitControl.stopDone(error_t error){}

}
