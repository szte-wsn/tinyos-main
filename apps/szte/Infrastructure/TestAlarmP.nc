/* Scheduler

	One measure = SLOT (sendWave or sampleRSSI)
	The set of slots = FRAME (1 sync/frame)
	The set of frames = SUPERFRAME

*/

#include "InfrastructureSettings.h"
#include "TestAlarm.h"
#include "RadioConfig.h"

#define SENDING_TIME 64

#define TX1_THRESHOLD 0
#define TX2_THRESHOLD 0
#define RX_THRESHOLD 0

#define NO_SYNC_TOLERANCE 5

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
	#ifdef ENABLE_DEBUG_SLOTS	
	uses interface AMSend;
	uses interface Timer<TMilli>;
	uses interface BusyWait<TMicro, uint16_t>;
	#endif
	#if defined(TEST_CALCULATION_TIMING)
	uses interface DiagMsg;
	#endif
}
implementation{

	enum {
    CHANNEL = 17,
		TRIM1 = 2,
		TRIM2 = 5,
  };
  
  enum {
		MEAS_SLOT = 80, //measure slot
		SYNC_SLOT = 150, //sync slot
		DEBUG_SLOT = 3000UL*NUMBER_OF_RX, //between super frames
		WAIT_SLOT_1 = 62,
		WAIT_SLOT_10 = 625,
		WAIT_SLOT_100 = 6250,
		WAIT_SLOT_CAL = 93,
	};

	typedef nx_struct sync_message_t{
		nx_uint8_t frame;
		nx_uint8_t freq[NUMBER_OF_RX];
		nx_uint8_t phase[NUMBER_OF_RX];
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

	enum {
		NO_SYNC = 0,
	};

	typedef struct schedule_t{
		uint8_t work;
	}schedule_t;
	
	#ifdef TEST_CALCULATION_TIMING
	uint32_t sentpacket = 0;
	uint32_t droppacket = 0;
	#endif

	message_t debugPacket;
	message_t syncPacket[2];
	uint8_t currentSyncPacket=0;
	norace sync_message_t* currentSyncPayload;
	norace uint8_t processBufferState=PROCESS_IDLE;//only the change PROCESS_IDLE->PROCESS_CHANGEBUFFER is legal in atomic context
  
	norace uint8_t activeMeasure=0;
	norace uint32_t firetime;
	norace uint32_t startOfFrame;
	norace uint8_t buffer[NUMBER_OF_RX][BUFFER_LEN];
	norace uint8_t measureBuffer = 0;
	norace uint8_t processBuffer=0;
	
	norace uint8_t unsynchronized;
	
	#ifdef ENABLE_DEBUG_SLOTS
	uint16_t sendedBytesCounter=0;
	norace uint8_t sendedMeasureCounter = 0;
	uint8_t sendedMessageCounter = 0;
	uint8_t failedSendCounter = 0;
	task void sendWaveform();
	task void debugProcess();
	#endif
	task void sendSync();
	task void sendDummySync();
	task void processData();
	
	#ifdef MEASURE_CPU_LOAD
	uint32_t superframeStart;
	uint32_t lastTime;
	uint32_t busyTime;
	uint32_t lastFrame;
	uint32_t lastBusy;
	task void measureTask(){
		atomic{
			uint32_t now = call Alarm.getNow();
			if( (int32_t)(now - lastTime) > 1 ){
				busyTime += now - lastTime;
			}
			lastTime = now;
		}
		post measureTask();
	}
	#endif
	
	event void Boot.booted(){
		call SplitControl.start();
		unsynchronized = NO_SYNC;
		call Leds.set(0xff);
	}
	
	event void SplitControl.startDone(error_t error){
		if(TOS_NODE_ID <= NUMBER_OF_INFRAST_NODES){
			currentSyncPayload = (sync_message_t*)call TimeSyncAMSend.getPayload(&syncPacket[currentSyncPacket],sizeof(sync_message_t));
			startOfFrame = call Alarm.getNow();
			firetime = 0; 
			call Alarm.startAt(startOfFrame, 100);
		}
		#ifdef MEASURE_CPU_LOAD
		post measureTask();
		lastTime = call Alarm.getNow();
		busyTime = 0;
		#endif
	}

	event void SplitControl.stopDone(error_t error){}

	void startAlarm(uint8_t nextMeas, uint32_t start,uint32_t fire){
		uint8_t nextMeasType = read_uint8_t(&(motesettings[TOS_NODE_ID-1][nextMeas]));
		if(nextMeasType==TX1){
				call Alarm.startAt(start,fire+TX1_THRESHOLD);
			}else if(nextMeasType==TX2){
				call Alarm.startAt(start,fire+TX2_THRESHOLD);
			}else if(nextMeasType==RX){
				call Alarm.startAt(start,fire+RX_THRESHOLD);
			}else{
				call Alarm.startAt(start,fire);
		}
	}

	async event void Alarm.fired(){
		uint8_t measType = read_uint8_t(&(motesettings[TOS_NODE_ID-1][activeMeasure]));
		error_t err = SUCCESS;
		//set up the next alarm first
		switch( measType ){
			case RSYN:
			case SSYN:
			case DSYN:{
				startOfFrame = startOfFrame+firetime;
				firetime = SYNC_SLOT;
			} break;
			case TX1:
			case TX2:
			case RX:
			case NTRX:{
				firetime += MEAS_SLOT;
			}break;
			case W1:{
				firetime += WAIT_SLOT_1;
			}break;
			case W10:{
				firetime += WAIT_SLOT_10;
			}break;
			case W100:{
				firetime += WAIT_SLOT_100;
			}break;
			case DEB:
			case NDEB:{
				firetime += DEBUG_SLOT;
			}break;
		}
		activeMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
		startAlarm(activeMeasure,startOfFrame,firetime);
		
		switch( measType ){
			case RSYN:{
				if(unsynchronized != NO_SYNC){
					unsynchronized--;
				}
			}break;
			case SSYN:{
				currentSyncPayload->frame = activeMeasure;
				post sendSync();
			}break;
			case DSYN:{
				currentSyncPayload->frame = activeMeasure;
				post sendDummySync();
			} break;
			case TX1:{
				if(unsynchronized != NO_SYNC){
					err = call RadioContinuousWave.sendWave(CHANNEL,TRIM1, RFA1_DEF_RFPOWER, SENDING_TIME);
				}
			} break;
			case TX2:{
				if(unsynchronized != NO_SYNC){
					err = call RadioContinuousWave.sendWave(CHANNEL,TRIM2, RFA1_DEF_RFPOWER, SENDING_TIME);
				}
			} break;
			case RX:{
				if(unsynchronized != NO_SYNC){
					uint16_t time = 0;
					#ifndef DEBUG_COLLECTOR
					err = call RadioContinuousWave.sampleRssi(CHANNEL, buffer[measureBuffer], BUFFER_LEN, &time);
					#else
					for(time=0;time<BUFFER_LEN;time++){
						buffer[measureBuffer][time]=activeMeasure; //it's already incremented
					}
					#endif
					if(processBufferState == PROCESS_IDLE){
						processBufferState++;
						processBuffer = measureBuffer;
						post processData();
					}
					measureBuffer = (measureBuffer + 1) % NUMBER_OF_RX;
				}
			}break;
			case DEB:{
				if(unsynchronized != NO_SYNC){
					post debugProcess();
				}
			}break;
		}
		
		if( err != SUCCESS ){
			call Leds.led1Toggle();
		}
		
		if(activeMeasure == 0){
			call Leds.led0Toggle();
			#ifdef ENABLE_DEBUG_SLOTS
			sendedMeasureCounter = 0;
			#endif
			#ifdef MEASURE_CPU_LOAD
			lastFrame = call Alarm.getNow() - superframeStart;
			lastBusy = busyTime;
			superframeStart = call Alarm.getNow();
			busyTime = 0;
			#endif
		}
		if(unsynchronized == NO_SYNC){
			call Leds.set( 0xff );
		}
	}
	/*
		Sends sync message.
	*/
	task void sendSync(){
		#ifdef TEST_CALCULATION_TIMING
		int8_t temp=NUMBER_OF_RX-1;
		#endif
		#ifdef MEASURE_CPU_LOAD
		currentSyncPayload->freq[0] = lastFrame;
		currentSyncPayload->freq[1] = lastBusy;
		#endif
		
		processBufferState=PROCESS_IDLE;
		//workaround
		if( 0 < (int32_t)(call Alarm.getNow()-startOfFrame) )
    		call TimeSyncAMSend.send(0xFFFF, &syncPacket[currentSyncPacket], sizeof(sync_message_t), startOfFrame);
		if( currentSyncPayload->phase[NUMBER_OF_RX-1] == 255 )
			call Leds.led3Toggle();
		#ifdef TEST_CALCULATION_TIMING
		sentpacket+=NUMBER_OF_RX;
		while( temp>=0 && currentSyncPayload->phaseRef[temp] == 0 ){
			droppacket++;
			temp--;
		}
		if(call DiagMsg.record()){
			call DiagMsg.uint32(sentpacket);
			call DiagMsg.uint32(droppacket);
			call DiagMsg.send();
		}
		#endif
		currentSyncPacket = currentSyncPacket==0?1:0;
		currentSyncPayload = (sync_message_t*)call TimeSyncAMSend.getPayload(&syncPacket[currentSyncPacket],sizeof(sync_message_t));
		memset(currentSyncPayload, 0, sizeof(sync_message_t)-NUMBER_OF_RX);
		memset(currentSyncPayload->phase, 255, NUMBER_OF_RX);
	}
	
	task void sendDummySync(){
		call TimeSyncAMSend.send(0xFFFF, &syncPacket[currentSyncPacket], sizeof(sync_message_t), startOfFrame);
	}

	task void processData(){
    #ifndef DISABLE_PROCESSING
		switch(processBufferState){
			case PROCESS_IDLE://we probably run out of calculation time
				return;
				break;
			case PROCESS_CHANGEBUFFER:
				call MeasureWave.changeData(buffer[processBuffer], BUFFER_LEN);
				break;
			case PROCESS_PHASEREF:
				call MeasureWave.getPhaseRef();
				break;
			case PROCESS_FILTER:
				call MeasureWave.filter();
				break;
			case PROCESS_MIN:
				call MeasureWave.getMinAmplitude();
				break;
			case PROCESS_MAX:
				call MeasureWave.getMaxAmplitude();
				break;
			case PROCESS_FREQ:
				#ifndef DEBUG_COLLECTOR
				currentSyncPayload->freq[processBuffer] = call MeasureWave.getPeriod();
				#else
				currentSyncPayload->freq[processBuffer] = buffer[processBuffer][0];
				#endif
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
    #endif
	}

	/*
		SYNC msg received
	*/
	event message_t* SyncReceive.receive(message_t* bufPtr, void* payload, uint8_t len){
		sync_message_t* msg = (sync_message_t*)payload;
		if(call TimeSyncPacket.isValid(bufPtr)){
			if(msg->frame == activeMeasure || unsynchronized==NO_SYNC){
				//int32_t diff = (int32_t)(startOfFrame -  call TimeSyncPacket.eventTime(bufPtr));
				//workaround
				if( (int32_t)(call TimeSyncPacket.eventTime(bufPtr) - call Alarm.getNow()) > 0){	
					call Leds.led2Toggle();
				}else{
					startOfFrame = call TimeSyncPacket.eventTime(bufPtr);
					firetime = SYNC_SLOT;
				}
				if(unsynchronized==NO_SYNC){
					int i;
					activeMeasure = msg->frame;
					measureBuffer = 0;
					for(i=0;i<activeMeasure;i++){
						if( read_uint8_t(&(motesettings[TOS_NODE_ID-1][i])) == RX ){
							measureBuffer++;
						}
					}
					measureBuffer = measureBuffer%NUMBER_OF_RX;
					call Alarm.startAt(startOfFrame,firetime);
          call Leds.set(0);
				}
				unsynchronized = NO_SYNC_TOLERANCE;
			}
		}
		return bufPtr;
	}

	/*
		Sync message sent
	*/
	event void TimeSyncAMSend.sendDone(message_t* msg, error_t error){
		//workaround
		if(0 > (int32_t)(call Alarm.getNow() - startOfFrame)){
			unsynchronized=NO_SYNC;
		}
	}

	#ifdef ENABLE_DEBUG_SLOTS
	/*
	 * What to do between super frames.
	 */
	task void debugProcess(){
		sendedBytesCounter = 0;
		sendedMessageCounter = 0;
		post sendWaveform();
	}
	
	task void sendWaveform(){
		uint8_t i;
		wave_message_t* msg = (wave_message_t*)call AMSend.getPayload(&debugPacket,sizeof(wave_message_t));
		msg->whichWaveform = sendedMeasureCounter;
		msg->whichPartOfTheWaveform = sendedMessageCounter;
		
		for(i=0;i<WAVE_MESSAGE_LENGTH;i++){
			if(sendedBytesCounter+i < BUFFER_LEN)
				msg->data[i] = buffer[sendedMeasureCounter][sendedBytesCounter+i];
		}
		if(call AMSend.send(0xFFFF, &debugPacket, sizeof(wave_message_t)) != SUCCESS){
			failedSendCounter++;
			if(failedSendCounter<4){
				post sendWaveform();
			}else{
				failedSendCounter = 0;
				sendedBytesCounter = 0;
				sendedMessageCounter = 0;
			}
		}
	}
	
	event void Timer.fired(){
		post sendWaveform();
	}
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error){
		sendedBytesCounter += WAVE_MESSAGE_LENGTH;
		sendedMessageCounter++;
		failedSendCounter = 0;
		if(sendedBytesCounter >= BUFFER_LEN){
			sendedBytesCounter = 0;
			sendedMessageCounter = 0;
			sendedMeasureCounter++;
		}
		if( sendedMeasureCounter < NUMBER_OF_RX ){
			atomic{
				call BusyWait.wait(1000);
			}
			post sendWaveform();
		}
	}
	#endif

}
