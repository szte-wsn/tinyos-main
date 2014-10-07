/* Scheduler

	One measure = SLOT (sendWave or sampleRSSI)
	The set of slots = FRAME (1 sync/frame)
	The set of frames = SUPERFRAME

*/

#include "InfrastructureSettings.h"
#include "TestAlarm.h"
#include "RadioConfig.h"

#define SENDING_TIME 64
#define BUFFER_LEN 480

#define TX1_THRESHOLD 0
#define TX2_THRESHOLD 0
#define RX_THRESHOLD 0

module TestAlarmP{
	uses interface Boot;
	uses interface SplitControl;
	uses interface Leds;
	uses interface Alarm<T62khz, uint32_t> as Alarm;
	uses interface RadioContinuousWave;
	uses interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSend;
	uses interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacket;
	uses interface Receive as SyncReceive;
	uses interface MeasureWave;
	#ifdef SEND_WAVEFORM	
	uses interface AMSend;
	#endif
}
implementation{

	enum {
		CHANNEL = 11,
		TRIM1 = 0,
		TRIM2 = 7,
  };
  
  enum {
		MEAS_SLOT = 80, //measure slot
		SYNC_SLOT = 150, //sync slot
		DEBUG_SLOT = 10000, //between super frames
		WAIT_SLOT_1 = 62,
		WAIT_SLOT_10 = 625,
		WAIT_SLOT_100 = 6250,
	};

	typedef nx_struct sync_message_t{
		nx_uint8_t frame;
		nx_uint8_t phaseRef[NUMBER_OF_RX];
		nx_uint16_t freq[NUMBER_OF_RX];
		nx_uint8_t phase[NUMBER_OF_RX];
		nx_uint8_t min[NUMBER_OF_RX];
		nx_uint8_t max[NUMBER_OF_RX];
	} sync_message_t;
	
	enum {
		PROCESS_IDLE=0,
		PROCESS_CHANGEBUFFER=1,
		PROCESS_PHASEREF=2,
		PROCESS_FILTER=3,
		PROCESS_MIN=4,
		PROCESS_MAX=5,
		PROCESS_FREQ=6,
		PROCESS_PHASE=7,
		PROCESS_DONE=8,
	};

	typedef struct schedule_t{
		uint8_t work;
	}schedule_t;
  

	norace uint8_t settings[NUMBER_OF_SLOTS];
	norace bool waitToStart=TRUE;
	message_t debugPacket;
	message_t syncPacket[2];
	uint8_t currentSyncPacket=0;
	sync_message_t* currentSyncPayload;
	norace uint8_t processBufferState=PROCESS_IDLE;//only the change PROCESS_IDLE->PROCESS_CHANGEBUFFER is legal in atomic context
  
	norace uint8_t activeMeasure=0;
	norace uint32_t firetime;
	norace uint32_t startOfFrame;
	norace uint8_t buffer[NUMBER_OF_RX][BUFFER_LEN];
	norace uint8_t measureBuffer = 0;
	norace uint8_t processBuffer=0;
	#ifdef SEND_WAVEFORM
	uint16_t sendedBytesCounter=0;
	uint8_t sendedMeasureCounter = WFSEND_STARTINDEX;
	uint8_t sendedMessageCounter = 0;
	uint8_t failedSendCounter = 0;
	task void sendWaveform();
	task void debugProcess();
	#endif
	task void sendSync();
	task void sendDummySync();
	task void processData();
	
	event void Boot.booted(){
		uint8_t i;
		call SplitControl.start();
		firetime = 65000UL;
		startOfFrame = firetime;
		for(i=0;i<NUMBER_OF_SLOTS;i++){
			settings[i] = read_uint8_t(&(motesettings[TOS_NODE_ID-1][i]));
		}
	}
	
	event void SplitControl.startDone(error_t error){
		if(TOS_NODE_ID <= NUMBER_OF_INFRAST_NODES){
			currentSyncPayload = (sync_message_t*)call TimeSyncAMSend.getPayload(&syncPacket[currentSyncPacket],sizeof(sync_message_t));
			call Alarm.startAt(0,(firetime+((uint32_t)TOS_NODE_ID<<16)));
			firetime = 0; //! 
		}
	}

	event void SplitControl.stopDone(error_t error){}

	void startAlarm(uint8_t nextMeas, uint32_t start,uint32_t fire){
		if(settings[nextMeas]==TX1){
				call Alarm.startAt(start,fire+TX1_THRESHOLD);
			}else if(settings[nextMeas]==TX2){
				call Alarm.startAt(start,fire+TX2_THRESHOLD);
			}else if(settings[nextMeas]==RX){
				call Alarm.startAt(start,fire+RX_THRESHOLD);
			}else{
				call Alarm.startAt(start,fire);
		}
	}

	async event void Alarm.fired(){
		if(waitToStart){
			waitToStart = FALSE;
		}
		call Leds.set(activeMeasure);
		if(settings[activeMeasure]==RSYN){//waits for SYNC in this frame
			activeMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
			startOfFrame = startOfFrame+firetime;
			firetime = SYNC_SLOT;
			startAlarm(activeMeasure,startOfFrame,firetime);
			return;
		}
		if(settings[activeMeasure]==TX1 || settings[activeMeasure]==TX2 || settings[activeMeasure]==RX || settings[activeMeasure]==NTRX){
			firetime += MEAS_SLOT;
			startAlarm((activeMeasure+1)%NUMBER_OF_SLOTS,startOfFrame,firetime);
		}
		if(settings[activeMeasure]==TX1){ //sender
			call RadioContinuousWave.sendWave(CHANNEL,TRIM1, RFA1_DEF_RFPOWER, SENDING_TIME);
		}else if(settings[activeMeasure]==TX2){
			call RadioContinuousWave.sendWave(CHANNEL,TRIM2, RFA1_DEF_RFPOWER, SENDING_TIME);
		}else if(settings[activeMeasure]==RX){ //receiver
			uint16_t time = 0;
			call RadioContinuousWave.sampleRssi(CHANNEL, buffer[measureBuffer], BUFFER_LEN, &time);
			if(processBufferState == PROCESS_IDLE){
				processBufferState++;
				processBuffer = measureBuffer;
				post processData();
			}
			measureBuffer = (measureBuffer + 1) % NUMBER_OF_RX;
    }else if(settings[activeMeasure]==SSYN){//sends SYNC in this frame
			post sendSync();
		} else if(settings[activeMeasure]==DSYN){
			post sendDummySync();
		}else if(settings[activeMeasure]==DEB || settings[activeMeasure]==NDEB){
			firetime += DEBUG_SLOT;
			startAlarm((activeMeasure+1)%NUMBER_OF_SLOTS,startOfFrame,firetime);
			#ifdef SEND_WAVEFORM
			if(settings[activeMeasure]==DEB){
				post debugProcess();
			}
			#endif
		}else if(settings[activeMeasure]==W1){
			firetime += WAIT_SLOT_1;
			startAlarm((activeMeasure+1)%NUMBER_OF_SLOTS,startOfFrame,firetime);
		}else if(settings[activeMeasure]==W10){
			firetime += WAIT_SLOT_10;
			startAlarm((activeMeasure+1)%NUMBER_OF_SLOTS,startOfFrame,firetime);
		}else if(settings[activeMeasure]==W100){
			firetime += WAIT_SLOT_100;
			startAlarm((activeMeasure+1)%NUMBER_OF_SLOTS,startOfFrame,firetime);
		}
		activeMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
		if(activeMeasure == 0){
			#ifdef SEND_WAVEFORM
			sendedMeasureCounter = WFSEND_STARTINDEX;
			#endif
		}
	}
	/*
		Sends sync message.
	*/
	task void sendSync(){
		currentSyncPayload->frame = activeMeasure; //activeMeasure is incremented before this task, so it indicates the next slot
		
		startOfFrame = startOfFrame+firetime;
		firetime = SYNC_SLOT;
		startAlarm(activeMeasure,startOfFrame,firetime);
		processBufferState=PROCESS_IDLE;
    call TimeSyncAMSend.send(0xFFFF, &syncPacket[currentSyncPacket], sizeof(sync_message_t), startOfFrame);
		currentSyncPacket = (currentSyncPacket+1)%2;
		currentSyncPayload = (sync_message_t*)call TimeSyncAMSend.getPayload(&syncPacket[currentSyncPacket],sizeof(sync_message_t));
		memset(currentSyncPayload, 0, sizeof(sync_message_t));
	}
	
	task void sendDummySync(){
		startOfFrame = startOfFrame+firetime;
		firetime = SYNC_SLOT;
		startAlarm(activeMeasure,startOfFrame,firetime);
		call TimeSyncAMSend.send(0xFFFF, &syncPacket[currentSyncPacket], sizeof(sync_message_t), startOfFrame);
	}

	task void processData(){
		switch(processBufferState){
			case PROCESS_IDLE://we probably run out of calculation time
				return;
				break;
			case PROCESS_CHANGEBUFFER:
				call MeasureWave.changeData(buffer[processBuffer], BUFFER_LEN);
				break;
			case PROCESS_PHASEREF:
				currentSyncPayload->phaseRef[processBuffer] = call MeasureWave.getPhaseRef();
				break;
			case PROCESS_FILTER:
				call MeasureWave.filter();
				break;
			case PROCESS_MIN:
				currentSyncPayload->min[processBuffer] = call MeasureWave.getMinAmplitude();
				break;
			case PROCESS_MAX:
				currentSyncPayload->max[processBuffer] = call MeasureWave.getMaxAmplitude();
				break;
			case PROCESS_FREQ:
				currentSyncPayload->freq[processBuffer] = call MeasureWave.getPeriod();
				break;
			case PROCESS_PHASE:
				currentSyncPayload->phase[processBuffer] = call MeasureWave.getPhase();
				break;
		}
		if( ++processBufferState == PROCESS_DONE ){
			processBuffer = (processBuffer+1)%NUMBER_OF_RX;
			if( processBuffer == measureBuffer ){
				processBufferState = PROCESS_IDLE;
				return;
			} else {
				processBufferState = PROCESS_CHANGEBUFFER;
			}
		}
		post processData();
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
					measureBuffer = 0;
					for(i=0;i<activeMeasure;i++){
						if(settings[i]==RX){
							measureBuffer++;
						}
					}
					measureBuffer = measureBuffer%NUMBER_OF_RX;
					processBuffer = measureBuffer-1;
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

	#ifdef SEND_WAVEFORM
	/*
	 * What to do between super frames.
	 */
	task void debugProcess(){
		sendedBytesCounter = 0;
		sendedMessageCounter = 0;
		post sendWaveform();
	}
	
	task void sendWaveform(){
		if(sendedBytesCounter < BUFFER_LEN){
			uint8_t i;
			wave_message_t* msg = (wave_message_t*)call AMSend.getPayload(&debugPacket,sizeof(wave_message_t));
			msg->whichWaveform = sendedMeasureCounter;
			msg->whichPartOfTheWaveform = sendedMessageCounter;
			for(i=0;i<WAVE_MESSAGE_LENGTH;i++){
				if(sendedBytesCounter+i < BUFFER_LEN)
					msg->data[i] = buffer[sendedMeasureCounter][sendedBytesCounter+i];
			}
			if(call AMSend.send(0xFFFF, &debugPacket, sizeof(wave_message_t)) == SUCCESS){
				sendedMessageCounter++;
			}else{
				failedSendCounter++;
				if(failedSendCounter<4){
					post sendWaveform();
				}else{
					failedSendCounter = 0;
					sendedBytesCounter = 0;
					sendedMessageCounter = 0;
				}
			}
		}else{
			sendedBytesCounter = 0;
			sendedMessageCounter = 0;
			sendedMeasureCounter = (sendedMeasureCounter+1)%NUMBER_OF_RX;
		}
	}
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error){
		sendedBytesCounter += WAVE_MESSAGE_LENGTH;
		post sendWaveform();
	}
	#endif

}
