/* Scheduler

	One measure = SLOT (sendWave or sampleRSSI)
	The set of slots = FRAME (1 sync/frame)
	The set of frames = SUPERFRAME

*/

#include "TestAlarm.h"
#include "RadioConfig.h"

#define NUMBER_OF_INFRAST_NODES 4
#define NUMBER_OF_FRAMES 4
#define NUMBER_OF_SLOT_IN_FRAME 4
#define NUMBER_OF_RX 6
#define SENDING_TIME 64
#define BUFFER_LEN 500

#define TX1_THRESHOLD 0
#define TX2_THRESHOLD 0
#define RX_THRESHOLD 0

#define AMPLITUDE_THRESHOLD 5
#define LEADTIME 10
#define START_OFFSET 16

#ifdef SEND_WAVEFORM
#define WAVE_MESSAGE_LENGTH 60
#define WAVE_SENDER_ID 1
#define SENDED_MEASURE_NUMBER 1
#endif

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
	uses interface Process;
}
implementation{

	enum {
		CHANNEL = 11,
		MODE = 0,
		TRIM1 = 0,
		TRIM2 = 7,
		TX1 = 0, //sendWave 1
		TX2 = 1, //sendWave 1
		RX = 2, //sampleRSSI
		SEND_SYNC=3, //sends sync message
		RECV_SYNC=4, //waits for sync message
		NUMBER_OF_SLOTS = NUMBER_OF_SLOT_IN_FRAME*NUMBER_OF_FRAMES,
		MEAS_SLOT = 50000U, //measure slot
		SYNC_SLOT = 250, //sync slot
		SEND_SLOT = 65000U, //between super frames
	};

	typedef nx_struct sync_message_t{
		nx_uint8_t frame;
		nx_uint8_t phaseRef[NUMBER_OF_RX];
		nx_uint16_t freq[NUMBER_OF_RX];
		nx_uint8_t phase[NUMBER_OF_RX];
		nx_uint8_t minmax[NUMBER_OF_RX];
	} sync_message_t;

	#ifdef SEND_WAVEFORM
	typedef nx_struct wave_message_t{
		nx_uint8_t data[WAVE_MESSAGE_LENGTH+4];
	} wave_message_t;
	#endif


	typedef struct schedule_t{
		uint8_t work;
	}schedule_t;

	norace schedule_t settings[NUMBER_OF_SLOTS];
	norace bool waitToStart=TRUE;
	message_t packet;
	norace uint8_t activeMeasure=0;
	norace uint32_t firetime;
	norace uint32_t startOfFrame;
	norace uint8_t buffer[NUMBER_OF_RX][BUFFER_LEN];
	norace uint8_t bufferCounter = 0;
	norace uint8_t tempBufferCounter=0;
	norace uint8_t phases[NUMBER_OF_RX];
	norace uint16_t freqs[NUMBER_OF_RX];
	norace uint8_t minAmplitudes[NUMBER_OF_RX];
	norace uint8_t maxAmplitudes[NUMBER_OF_RX];
	norace uint8_t phaseRefs[NUMBER_OF_RX];
	#ifdef SEND_WAVEFORM
	uint16_t sendedBytesCounter=0;
	task void sendWaveform();
	#endif
	task void measureDone();
	task void sendSync();
	task void processData();
	
	event void Boot.booted(){
		call SplitControl.start();
		firetime = 300000UL;
		startOfFrame = firetime-(NUMBER_OF_SLOT_IN_FRAME-1)*MEAS_SLOT - SYNC_SLOT;
		if(NUMBER_OF_INFRAST_NODES == 5){
			if(TOS_NODE_ID==1){
				settings[0].work=SEND_SYNC;
				settings[1].work=TX1;
				settings[2].work=TX1;
				settings[3].work=RECV_SYNC;
				settings[4].work=TX1;
				settings[5].work=TX1;
				settings[6].work=RECV_SYNC;
				settings[7].work=TX1;
				settings[8].work=TX1;
				settings[9].work=RECV_SYNC;
				settings[10].work=TX1;
				settings[11].work=TX1;
				settings[12].work=RECV_SYNC;
				settings[13].work=TX1;
				settings[14].work=TX1;
			}
			if(TOS_NODE_ID==2){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=RX;
				settings[3].work=SEND_SYNC;
				settings[4].work=RX;
				settings[5].work=RX;
				settings[6].work=RECV_SYNC;
				settings[7].work=RX;
				settings[8].work=RX;
				settings[9].work=RECV_SYNC;
				settings[10].work=RX;
				settings[11].work=RX;
				settings[12].work=RECV_SYNC;
				settings[13].work=RX;
				settings[14].work=RX;
			}
			if(TOS_NODE_ID==3){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=TX2;
				settings[3].work=RECV_SYNC;
				settings[4].work=TX1;
				settings[5].work=RX;
				settings[6].work=SEND_SYNC;
				settings[7].work=RX;
				settings[8].work=RX;
				settings[9].work=RECV_SYNC;
				settings[10].work=TX1;
				settings[11].work=TX2;
				settings[12].work=RECV_SYNC;
				settings[13].work=RX;
				settings[14].work=RX;
			}
			if(TOS_NODE_ID==4){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=RX;
				settings[3].work=RECV_SYNC;
				settings[4].work=TX2;
				settings[5].work=TX1;
				settings[6].work=RECV_SYNC;
				settings[7].work=RX;
				settings[8].work=RX;
				settings[9].work=SEND_SYNC;
				settings[10].work=RX;
				settings[11].work=TX1;
				settings[12].work=RECV_SYNC;
				settings[13].work=TX2;
				settings[14].work=RX;
			}
			if(TOS_NODE_ID==5){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=RX;
				settings[3].work=RECV_SYNC;
				settings[4].work=RX;
				settings[5].work=TX2;
				settings[6].work=RECV_SYNC;
				settings[7].work=TX1;
				settings[8].work=RX;
				settings[9].work=RECV_SYNC;
				settings[10].work=RX;
				settings[11].work=RX;
				settings[12].work=SEND_SYNC;
				settings[13].work=TX1;
				settings[14].work=TX2;
			}
		} else if(NUMBER_OF_INFRAST_NODES == 4){
			if(TOS_NODE_ID==1){
				settings[0].work=SEND_SYNC;
				settings[1].work=TX1;
				settings[2].work=TX1;
				settings[3].work=RX;
				settings[4].work=RECV_SYNC;
				settings[5].work=TX1;
				settings[6].work=TX1;
				settings[7].work=RX;
				settings[8].work=RECV_SYNC;
				settings[9].work=TX1;
				settings[10].work=TX1;
				settings[11].work=RX;
				settings[12].work=RECV_SYNC;
				settings[13].work=RX;
				settings[14].work=RX;
				settings[15].work=RX;
			}
			if(TOS_NODE_ID==2){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=RX;
				settings[3].work=RX;
				settings[4].work=SEND_SYNC;
				settings[5].work=TX2;
				settings[6].work=RX;
				settings[7].work=TX1;
				settings[8].work=RECV_SYNC;
				settings[9].work=TX2;
				settings[10].work=RX;
				settings[11].work=TX1;
				settings[12].work=RECV_SYNC;
				settings[13].work=TX1;
				settings[14].work=TX1;
				settings[15].work=RX;
			}
			if(TOS_NODE_ID==3){
				settings[0].work=RECV_SYNC;
				settings[1].work=TX2;
				settings[2].work=RX;
				settings[3].work=TX1;
				settings[4].work=RECV_SYNC;
				settings[5].work=RX;
				settings[6].work=RX;
				settings[7].work=RX;
				settings[8].work=SEND_SYNC;
				settings[9].work=RX;
				settings[10].work=TX2;
				settings[11].work=TX2;
				settings[12].work=RECV_SYNC;
				settings[13].work=TX2;
				settings[14].work=RX;
				settings[15].work=TX1;
			}
			if(TOS_NODE_ID==4){
				settings[0].work=RECV_SYNC;
				settings[1].work=RX;
				settings[2].work=TX2;
				settings[3].work=TX2;
				settings[4].work=RECV_SYNC;
				settings[5].work=RX;
				settings[6].work=TX2;
				settings[7].work=TX2;
				settings[8].work=RECV_SYNC;
				settings[9].work=RX;
				settings[10].work=RX;
				settings[11].work=RX;
				settings[12].work=SEND_SYNC;
				settings[13].work=RX;
				settings[14].work=TX2;
				settings[15].work=TX2;
			}
		}
	}
	
	event void SplitControl.startDone(error_t error){
		call Alarm.startAt(0,(firetime+((uint32_t)TOS_NODE_ID<<16)));
	}

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
		if(waitToStart){
			waitToStart = FALSE;
		}
		call Leds.set(activeMeasure);
		if(activeMeasure == NUMBER_OF_SLOTS){//end of superframe
			call Alarm.stop();
			post measureDone();
			return;
		}
		if(settings[activeMeasure].work==RECV_SYNC){//waits for SYNC in this frame
			activeMeasure++;
			firetime = SYNC_SLOT;
			startOfFrame = startOfFrame+(NUMBER_OF_SLOT_IN_FRAME-1)*MEAS_SLOT+SYNC_SLOT;
			if(settings[activeMeasure].work==TX1){
				call Alarm.startAt(startOfFrame,firetime+TX1_THRESHOLD);
			}else if(settings[activeMeasure].work==TX2){
				call Alarm.startAt(startOfFrame,firetime+TX2_THRESHOLD);
			}else if(settings[activeMeasure].work==RX){
				call Alarm.startAt(startOfFrame,firetime+RX_THRESHOLD);
			}else{
				call Alarm.startAt(startOfFrame,firetime);
			}
			return;
		}
		if(settings[activeMeasure].work==TX1 || settings[activeMeasure].work==TX2 || settings[activeMeasure].work==RX){
			uint8_t nextMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
			firetime += MEAS_SLOT;
			if(settings[nextMeasure].work==TX1){
				call Alarm.startAt(startOfFrame,firetime+TX1_THRESHOLD);
			}else if(settings[nextMeasure].work==TX2){
				call Alarm.startAt(startOfFrame,firetime+TX2_THRESHOLD);
			}else if(settings[nextMeasure].work==RX){
				call Alarm.startAt(startOfFrame,firetime+RX_THRESHOLD);
			}else{
				call Alarm.startAt(startOfFrame,firetime);
			}
		}
		if(settings[activeMeasure].work==TX1 || settings[activeMeasure].work==TX2){ //sender
			call RadioContinuousWave.sendWave(CHANNEL,TRIM1, RFA1_DEF_RFPOWER, SENDING_TIME);
		}else if(settings[activeMeasure].work==RX){ //receiver
			uint16_t time = 0;
			//call Leds.set(1);
			call RadioContinuousWave.sampleRssi(CHANNEL, getBuffer(buffer[bufferCounter]), BUFFER_LEN, &time);
			tempBufferCounter = bufferCounter;
			bufferCounter = (bufferCounter+1)%NUMBER_OF_RX;
			post processData();
		}else if(settings[activeMeasure].work==SEND_SYNC){//sends SYNC in this frame
			post sendSync();
		}
			//activeMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
		activeMeasure++;
	}
	/*
		Sends sync message.
	*/
	task void sendSync(){
		uint8_t i;
		sync_message_t* msg = (sync_message_t*)call TimeSyncAMSend.getPayload(&packet,sizeof(sync_message_t));
		msg->frame = activeMeasure; //activeMeasure is incremented before this task, so it indicates the next slot
		
		for(i=0;i<NUMBER_OF_RX;i++){
			msg->phaseRef[i] = phaseRefs[i];
			msg->freq[i] = 2;//freqs[i];
			msg->phase[i] = 2;//phases[i];
			msg->minmax[i] = (minAmplitudes[i] & 0x0F) | ((maxAmplitudes[i] & 0x0F)<<4);
		}
		
		startOfFrame = startOfFrame+(NUMBER_OF_SLOT_IN_FRAME-1)*MEAS_SLOT+SYNC_SLOT;
		firetime = SYNC_SLOT;
		if(settings[activeMeasure].work==TX1){
			call Alarm.startAt(startOfFrame,firetime+TX1_THRESHOLD);
		}else if(settings[activeMeasure].work==TX2){
			call Alarm.startAt(startOfFrame,firetime+TX2_THRESHOLD);
		}else if(settings[activeMeasure].work==RX){
			call Alarm.startAt(startOfFrame,firetime+RX_THRESHOLD);
		}else{
			call Alarm.startAt(startOfFrame,firetime);
		}
		call TimeSyncAMSend.send(0xFFFF, &packet, sizeof(sync_message_t), startOfFrame);
		return;
	}

	task void processData(){
		/*call MeasureWave.changeData(getBuffer(buffer[tempBufferCounter]), BUFFER_LEN, AMPLITUDE_THRESHOLD, LEADTIME);
		phaseRefs[tempBufferCounter] = call MeasureWave.getPhaseRef();
 		minAmplitudes[tempBufferCounter] = call MeasureWave.getMinAmplitude() >> 1;
 		maxAmplitudes[tempBufferCounter] = call MeasureWave.getMaxAmplitude() >> 1;
		freqs[tempBufferCounter] = call MeasureWave.getPeriod();
 		phases[tempBufferCounter] = call MeasureWave.getPhase();*/
 		
 		call Process.changeData(getBuffer(buffer[tempBufferCounter]), BUFFER_LEN, AMPLITUDE_THRESHOLD, LEADTIME);
		phaseRefs[tempBufferCounter] = call Process.getStartPoint();
 		minAmplitudes[tempBufferCounter] = call Process.getMinAmplitude() >> 1;
 		maxAmplitudes[tempBufferCounter] = call Process.getMaxAmplitude() >> 1;
		//freqs[tempBufferCounter] = call Process.getPeriod();
 		//phases[tempBufferCounter] = call Process.getPhase();
	}


	event void AMSend.sendDone(message_t* bufPtr, error_t error){
		#ifdef SEND_WAVEFORM
		sendedBytesCounter += WAVE_MESSAGE_LENGTH;
		post sendWaveform();
		#endif
	}

	/*
		SYNC msg received
	*/
	event message_t* SyncReceive.receive(message_t* bufPtr, void* payload, uint8_t len){
		sync_message_t* msg = (sync_message_t*)payload;
		if(call TimeSyncPacket.isValid(bufPtr)){
			if(msg->frame == activeMeasure || waitToStart){
				startOfFrame = call TimeSyncPacket.eventTime(bufPtr);
				firetime = SYNC_SLOT;
				if(waitToStart){
					int i;
					activeMeasure = msg->frame;
					call Alarm.startAt(startOfFrame,firetime);
					waitToStart = FALSE;
					for(i=0;i<activeMeasure;i++){
						if(settings[i].work==RX){
							bufferCounter++;
						}
					}
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
		activeMeasure = 0;
		bufferCounter = 0;
		firetime += SEND_SLOT;
		if(settings[activeMeasure].work==TX1){
			call Alarm.startAt(startOfFrame,firetime+TX1_THRESHOLD);
		}else if(settings[activeMeasure].work==TX2){
			call Alarm.startAt(startOfFrame,firetime+TX2_THRESHOLD);
		}else if(settings[activeMeasure].work==RX){
			call Alarm.startAt(startOfFrame,firetime+RX_THRESHOLD);
		}else{
			call Alarm.startAt(startOfFrame,firetime);
		}
		startOfFrame = startOfFrame + SEND_SLOT;
		#ifdef SEND_WAVEFORM
		if(TOS_NODE_ID == WAVE_SENDER_ID){
			post sendWaveform();
		}
		#endif
	}
	#ifdef SEND_WAVEFORM
	task void sendWaveform(){
		if(sendedBytesCounter < BUFFER_LEN){
			uint8_t i;
			wave_message_t* msg = (wave_message_t*)call AMSend.getPayload(&packet,sizeof(wave_message_t));
			for(i=0;i<WAVE_MESSAGE_LENGTH;i++){
				if(sendedBytesCounter+i < BUFFER_LEN)
					msg->data[i] = buffer[SENDED_MEASURE_NUMBER][sendedBytesCounter+i];
			}
			call AMSend.send(0xFFFF, &packet, sizeof(wave_message_t));
		}else{
			sendedBytesCounter = 0;
		}
	}
	#endif

}
