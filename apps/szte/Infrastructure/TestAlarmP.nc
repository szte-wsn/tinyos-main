/* Scheduler

	One measure = SLOT (sendWave or sampleRSSI)
	The set of slots = FRAME (1 sync/frame)
	The set of frames = SUPERFRAME

*/

#include "TestAlarm.h"
#include "InfrastructureSettings.h"
#include "RadioConfig.h"

#define SENDING_TIME 64
#define BUFFER_LEN 500

#define TX1_THRESHOLD 0
#define TX2_THRESHOLD 0
#define RX_THRESHOLD 0

#define AMPLITUDE_THRESHOLD 2
#define LEADTIME 10
#define START_OFFSET 16

#ifdef SEND_WAVEFORM
#define WAVE_MESSAGE_LENGTH 80
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
}
implementation{

	enum {
		CHANNEL = 11,
		TRIM1 = 0,
		TRIM2 = 2,
  };
  
  enum {
		MEAS_SLOT = 10000, //measure slot
		SYNC_SLOT = 10000, //sync slot
		DEBUG_SLOT = 30000, //between super frames
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
		nx_uint8_t whichWaveform;
		nx_uint8_t whichPartOfTheWaveform;
		nx_uint8_t data[WAVE_MESSAGE_LENGTH+4];
	} wave_message_t;
	#endif


	typedef struct schedule_t{
		uint8_t work;
	}schedule_t;
  

	norace uint8_t settings[NUMBER_OF_SLOTS];
	norace bool waitToStart=TRUE;
	message_t debugPacket;
  message_t syncPacket[2];
  uint8_t currentSyncPacket=0;
  sync_message_t* currentSyncPayload;
  
	norace uint8_t activeMeasure=0;
	norace uint32_t firetime;
	norace uint32_t startOfFrame;
	norace uint8_t buffer[NUMBER_OF_RX][BUFFER_LEN];
	norace uint8_t measureBuffer = 0;
	norace uint8_t processBuffer=0;
	#ifdef SEND_WAVEFORM
	uint16_t sendedBytesCounter=0;
	uint8_t sendedMeasureCounter = 0;
	uint8_t sendedMessageCounter = 0;
	uint8_t failedSendCounter = 0;
	task void sendWaveform();
	#endif
	task void debugProcess();
	task void sendSync();
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
			measureBuffer = (measureBuffer+1)%NUMBER_OF_RX;
			post processData();
		}else if(settings[activeMeasure]==SSYN){//sends SYNC in this frame
			post sendSync();
		}else if(settings[activeMeasure]==DEB || settings[activeMeasure]==NDEB){
			firetime += DEBUG_SLOT;
			startAlarm((activeMeasure+1)%NUMBER_OF_SLOTS,startOfFrame,firetime);		
			if(settings[activeMeasure]==DEB){
				post debugProcess();
			}else{
				#ifdef SEND_WAVEFORM
				sendedBytesCounter = 0;
				sendedMessageCounter = 0;
				sendedMeasureCounter = 0;
				#endif
			}
		}
		activeMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
	}
	/*
		Sends sync message.
	*/
	task void sendSync(){
		currentSyncPayload->frame = activeMeasure; //activeMeasure is incremented before this task, so it indicates the next slot
		
		startOfFrame = startOfFrame+firetime;
		firetime = SYNC_SLOT;
		startAlarm(activeMeasure,startOfFrame,firetime);
    call TimeSyncAMSend.send(0xFFFF, &syncPacket[currentSyncPacket], sizeof(sync_message_t), startOfFrame);
		currentSyncPacket = (currentSyncPacket+1)%2;
		currentSyncPayload = (sync_message_t*)call TimeSyncAMSend.getPayload(&syncPacket[currentSyncPacket],sizeof(sync_message_t));
		memset(currentSyncPayload, 0, sizeof(sync_message_t));
	}

	task void processData(){
		call MeasureWave.changeData(buffer[processBuffer], BUFFER_LEN, AMPLITUDE_THRESHOLD, LEADTIME);
		currentSyncPayload->phaseRef[processBuffer] = call MeasureWave.getPhaseRef();
		currentSyncPayload->minmax[processBuffer] = call MeasureWave.getMaxAmplitude()<<4;//upper nibblet, without LSB
		currentSyncPayload->minmax[processBuffer] |= call MeasureWave.getMinAmplitude()>>1;//lower nibblet, without LSB
		currentSyncPayload->freq[processBuffer] = call MeasureWave.getPeriod();
		currentSyncPayload->phase[processBuffer] = call MeasureWave.getPhase();
		processBuffer = (processBuffer+1)%NUMBER_OF_RX;
		if( processBuffer != measureBuffer ){
			post processData();
		}
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
					measureBuffer = 0;
					for(i=0;i<activeMeasure;i++){
						if(settings[i]==RX){
							measureBuffer++;
						}
					}
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
	/*
		What to do between super frames.
	*/
	task void debugProcess(){
		#ifdef SEND_WAVEFORM
		post sendWaveform();
		#endif
	}
	#ifdef SEND_WAVEFORM
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
	#endif

}
