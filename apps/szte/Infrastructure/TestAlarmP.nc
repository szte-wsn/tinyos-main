/* Scheduler

	One measure = SLOT (sendWave or sampleRSSI)
	The set of slots = FRAME (1 sync/frame)
	The set of frames = SUPERFRAME

*/

#include "TestAlarm.h"


#define NUMBER_OF_INFRAST_NODES 4
#define NUMBER_OF_FRAMES 4
#define NUMBER_OF_SLOT_IN_FRAME 4
#define NUMBER_OF_RX 6
#define SENDING_TIME 1000
#define BUFFER_LEN 512

#define AMPLITUDE_THRESHOLD 2
#define LEADTIME 10
#define START_OFFSET 16

module TestAlarmP{
	uses interface Boot;
	uses interface SplitControl;
	uses interface Leds;
	uses interface Alarm<T62khz, uint32_t> as Alarm;
	uses interface RadioContinuousWave;
	uses interface AMSend;
	uses interface AMPacket;
	uses interface Packet;
	uses interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSend;
	uses interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacket;
	uses interface Receive as SyncReceive;
	uses interface MeasureWave;
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
		MEAS_SLOT = 10000, //measure slot
		SYNC_SLOT = 15000, //sync slot
		SEND_SLOT = 6200, //between super frames
		DUMMY_MIN = 15,
		DUMMY_MAX = 20,
	};

	typedef nx_struct sync_message_t{
		nx_uint8_t frame;
		nx_uint16_t freq[NUMBER_OF_RX];
		nx_uint8_t phase[NUMBER_OF_RX];
		nx_uint8_t minmax[NUMBER_OF_RX];
	} sync_message_t;


	typedef struct schedule_t{
		uint8_t work;
	}schedule_t;

	norace schedule_t settings[NUMBER_OF_SLOTS];
	norace bool waitToStart=TRUE;
	message_t packet;
	norace uint32_t startOfFrame;
	norace uint8_t activeMeasure=1;
	norace uint32_t firetime=0;
	uint8_t buffer[NUMBER_OF_RX][BUFFER_LEN];
	norace uint8_t bufferCounter = 0;
	norace uint8_t tempBufferCounter;
	uint8_t cnt=0;
	norace uint32_tphases[NUMBER_OF_RX],freqs[NUMBER_OF_RX];
	task void measureDone();
	task void measureStart();
	task void sendSync();
	task void processData();
	
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
				waitToStart = TRUE; //it will start the action
				firetime = 62000U;
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
			call Leds.set(activeMeasure);
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
				//call Leds.set(1);
				call RadioContinuousWave.sampleRssi(CHANNEL, getBuffer(buffer[bufferCounter]), BUFFER_LEN, &time);
				post processData();
				tempBufferCounter = bufferCounter;
				bufferCounter = (bufferCounter+1)%NUMBER_OF_RX;
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
		uint8_t i;
		sync_message_t* msg = (sync_message_t*)call TimeSyncAMSend.getPayload(&packet,sizeof(sync_message_t));
		msg->frame = activeMeasure;
		
		for(i=0;i<NUMBER_OF_RX;i++){
			msg->freq[i] = (uint16_t)freqs[i]; //=i for test
			msg->phase[i] = (uint8_t)phases[i]; //=i for test
			msg->minmax[i] = (DUMMY_MIN & 0x0F) | ((DUMMY_MAX & 0x0F)<<4);
		}
		
		startOfFrame = startOfFrame+(NUMBER_OF_SLOT_IN_FRAME-1)*MEAS_SLOT+SYNC_SLOT;
		firetime = SYNC_SLOT;
		call Alarm.startAt(startOfFrame,firetime);
		call TimeSyncAMSend.send(0xFFFF, &packet, sizeof(sync_message_t), startOfFrame);
		return;
	}

	task void processData(){
		call MeasureWave.changeData(getBuffer(buffer[tempBufferCounter]), BUFFER_LEN, AMPLITUDE_THRESHOLD, LEADTIME);
// 		minAmplitudes[tempBufferCounter] = call MeasureWave.getMaxAmplitude() >> 1;
// 		maxAmplitudes[tempBufferCounter] = call MeasureWave.getMaxAmplitude() >> 1;
		freqs[tempBufferCounter] = call MeasureWave.getPeriod();
		phases[tempBufferCounter] = call MeasureWave.getPhase();
	}


	event void AMSend.sendDone(message_t* bufPtr, error_t error){}

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

}
