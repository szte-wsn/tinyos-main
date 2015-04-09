/* Scheduler

	One measure = SLOT or FRAME (sendWave or sampleRSSI)
	The set of frames = SUPERFRAME

*/

#include "InfrastructureSettings.h"
#include "MeasureSettings.h"
#include "TestAlarm.h"
#include "RadioConfig.h"



module TestAlarmP{
	uses interface Boot;
	uses interface SplitControl;
	uses interface Leds;
	uses interface Alarm<TMcu, uint32_t> as Alarm;
	uses interface RadioContinuousWave;
	uses interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSend;
	uses interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacket;
	uses interface Receive as SyncReceive;
	uses interface MeasureWave;
	uses interface MeasureSettings;
	#ifdef ENABLE_AUTOTRIM
	uses interface AutoTrim;
	uses interface AMPacket;
	#endif
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

	typedef nx_struct sync_message_t{
		nx_uint8_t frame;
		nx_uint8_t freq[NUMBER_OF_RX];
		nx_uint8_t phase[NUMBER_OF_RX];
		nx_uint8_t rssis[NUMBER_OF_RX];
	} sync_message_t;

	enum {
		NO_SYNC = 0,
		NO_SYNC_TOLERANCE = NUMBER_OF_SLOTS,
	};

	message_t syncPacket[2];
	uint8_t currentSyncPacket=0;
	sync_message_t* currentSyncPayload;
	uint8_t syncFrame;
	norace bool processing = FALSE; //there's a non-critical race condition: it might won't start processing in time
  
	norace uint8_t activeMeasure=0;
	norace uint32_t firetime;
	norace uint32_t startOfFrame;
	norace uint8_t buffer[NUMBER_OF_RX][BUFFER_LEN];
	norace uint8_t measureBuffer = 0;
	norace uint8_t processBuffer=0;
	
	norace uint8_t unsynchronized;
	
	task void sendSync();
	task void sendDummySync();
	task void processData();
	
	#ifdef ENABLE_DEBUG_SLOTS
	message_t debugPacket;
	uint16_t sendedBytesCounter=0;
	norace uint8_t sendedMeasureCounter = 0;
	uint8_t sendedMessageCounter = 0;
	uint8_t failedSendCounter = 0;
	task void sendWaveform();
	task void debugProcess();
	#endif
	
	event void Boot.booted(){
		#ifdef ENABLE_AUTOTRIM
		call AutoTrim.processSchedule();
		#endif
		call SplitControl.start();
		unsynchronized = NO_SYNC;
		//call Leds.set(0xff);
	}
	
	event void SplitControl.startDone(error_t error){
		if(TOS_NODE_ID <= NUMBER_OF_INFRAST_NODES){
			currentSyncPayload = (sync_message_t*)call TimeSyncAMSend.getPayload(&syncPacket[currentSyncPacket],sizeof(sync_message_t));
			startOfFrame = call Alarm.getNow();
			firetime = 0; 
			call Alarm.startAt(startOfFrame, 4000);
		}
	}

	event void SplitControl.stopDone(error_t error){}
	
	//to store error values and the freezeError initial value
	enum{
		FREEZE_INITIAL_VALUE = 100, //measured in frames
		ERROR_NO_ERROR = 0,
		ERROR_BUSY_RADIO = 1,
		ERROR_WAVE_PROCESSING = 2,
		ERROR_POS_TIMESTAMP_BEFORE_SEND = 3,
		ERROR_POS_TIMESTAMP_BEFORE_SEND_DUMMY = 4,
		ERROR_LATE_SEND_DONE_SIGNAL = 5,
		ERROR_POS_TIMESTAMP_RECEIVED = 6,
		ERROR_UNSYNCHRONIZED = 7,
	};
	
	
	norace uint8_t freezeError = 0;
	
	//uses the 1st, 2nd and 3rd LED to show error status. Doesn't use led0!
	void setLeds(uint8_t status){
		if(freezeError == 0){
			call Leds.set( (call Leds.get() & 0x01) | ( (status<<1) & 0xFE) );
			if(status != ERROR_NO_ERROR){
				freezeError = FREEZE_INITIAL_VALUE;
			}
		}
	}

	void startAlarm(uint8_t nextMeas, uint32_t start,uint32_t fire){
		call Alarm.startAt(start, fire + call MeasureSettings.getDelay(read_uint8_t(&(motesettings[TOS_NODE_ID-1][nextMeas]))));
	}

	async event void Alarm.fired(){
		uint8_t measType = read_uint8_t(&(motesettings[TOS_NODE_ID-1][activeMeasure]));
		uint8_t prevMeasure = activeMeasure; //activeMeasure points the next slot in most of this function
		error_t err = SUCCESS;
		
		//set up timing for next slot
		if( measType == RSYN || measType == SSYN || measType == DSYN ){
			startOfFrame = startOfFrame+firetime;
			firetime = 0;
		}
		firetime += call MeasureSettings.getSlotTime(measType);
		activeMeasure = (activeMeasure+1)%NUMBER_OF_SLOTS;
		call Alarm.startAt(startOfFrame, firetime + call MeasureSettings.getDelay(read_uint8_t(&(motesettings[TOS_NODE_ID-1][activeMeasure]))));
		
		switch( measType ){
			case RSYN:{
				if(unsynchronized != NO_SYNC){
					unsynchronized--;
				}
			}break;
			case SSYN:{
				syncFrame = activeMeasure;
				post sendSync();
			}break;
			case DSYN:{
				syncFrame = activeMeasure;
				post sendDummySync();
			} break;
			case TX1A:
			case TX2A:
			case TX1B:
			case TX2B:{
				if(unsynchronized != NO_SYNC){
					err = call RadioContinuousWave.sendWave(
									call MeasureSettings.getChannel(measType, prevMeasure),
									call MeasureSettings.getTrim(measType, prevMeasure),
									call MeasureSettings.getTxPower(measType, prevMeasure),
									call MeasureSettings.getSendTime());
				}
			} break;
			case RXA:
			case RXB:{
				if(unsynchronized != NO_SYNC){
					uint16_t time = 0;
					#ifndef DEBUG_COLLECTOR
					err = call RadioContinuousWave.sampleRssi(call MeasureSettings.getChannel(measType, prevMeasure), buffer[measureBuffer], BUFFER_LEN, &time);
					#else
					for(time=0;time<BUFFER_LEN;time++){
						buffer[measureBuffer][time]=prevMeasure;
					}
					#endif
					if( !processing ){
						processing = TRUE;
						processBuffer = measureBuffer;
						post processData();
					}
					measureBuffer = (measureBuffer + 1) % NUMBER_OF_RX;
				}
			}break;
			#ifdef ENABLE_DEBUG_SLOTS
			case DEB:{
				if(unsynchronized != NO_SYNC){
					post debugProcess();
				}
			}break;
			#endif
		}
		
		if( err != SUCCESS ){
			setLeds(ERROR_BUSY_RADIO);
		}
		
		if(activeMeasure == 0){
			call Leds.led0Toggle();
			#ifdef ENABLE_DEBUG_SLOTS
			sendedMeasureCounter = 0;
			#endif
		}
		if(unsynchronized == NO_SYNC){
			setLeds(ERROR_UNSYNCHRONIZED);
		}else{
			if(freezeError > 0){
				freezeError--;
			}else{
				setLeds(ERROR_NO_ERROR);
			}
		}
	}
	/*
		Sends sync message.
	*/
	task void sendSync(){
		
		atomic{
			currentSyncPayload->frame = syncFrame;
			measureBuffer = 0;
		}
		
		//workaround
		if( 0 < (int32_t)(call Alarm.getNow()-startOfFrame) ){
			call TimeSyncAMSend.send(0xFFFF, &syncPacket[currentSyncPacket], sizeof(sync_message_t), startOfFrame);
		}else{
			setLeds(ERROR_POS_TIMESTAMP_BEFORE_SEND);
		}	
		//if( currentSyncPayload->phase[NUMBER_OF_RX-1] == 255 )
		//	setLeds(ERROR_WAVE_PROCESSING);
		
		currentSyncPacket = currentSyncPacket==0?1:0;
		currentSyncPayload = (sync_message_t*)call TimeSyncAMSend.getPayload(&syncPacket[currentSyncPacket],sizeof(sync_message_t));
		processing = FALSE;
		memset(currentSyncPayload, 0, sizeof(sync_message_t)-NUMBER_OF_RX);
		memset(currentSyncPayload->phase, 255, NUMBER_OF_RX);
	}
	
	task void sendDummySync(){
		atomic{
			currentSyncPayload->frame = syncFrame;
		}
		//workaround
		if( 0 < (int32_t)(call Alarm.getNow()-startOfFrame) ){
			call TimeSyncAMSend.send(0xFFFF, &syncPacket[currentSyncPacket], sizeof(sync_message_t), startOfFrame);
		}else{
			setLeds(ERROR_POS_TIMESTAMP_BEFORE_SEND_DUMMY);
		}	
	}

	task void processData(){
		#ifndef DISABLE_PROCESSING
		if ( !processing ) //the message was sent between processData tasks
			return;
		call MeasureWave.changeData(buffer[processBuffer], BUFFER_LEN);
		currentSyncPayload->freq[processBuffer] = call MeasureWave.getPeriod();
		currentSyncPayload->phase[processBuffer] = call MeasureWave.getPhase();
		currentSyncPayload->rssis[processBuffer] = (call MeasureWave.getRssi1()>0xf?0xf:call MeasureWave.getRssi1()) << 4;
		currentSyncPayload->rssis[processBuffer] |= call MeasureWave.getRssi2()>0xf?0xf:call MeasureWave.getRssi2();
		#ifdef DEBUG_COLLECTOR
		currentSyncPayload->freq[processBuffer] = buffer[processBuffer][0];
		#endif
		
		processBuffer = (processBuffer+1)%NUMBER_OF_RX;
		if ( processBuffer != measureBuffer ){
			post processData();
		} else {
			processing = FALSE;
		}
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
					setLeds(ERROR_POS_TIMESTAMP_RECEIVED);
				}else{
					startOfFrame = call TimeSyncPacket.eventTime(bufPtr);
					firetime = SYNC_SLOT;
					#ifdef ENABLE_AUTOTRIM
					call AutoTrim.processSyncMessage((uint8_t)(call AMPacket.source(bufPtr)),payload);
					#endif
				}
				if(unsynchronized==NO_SYNC){
					int i;
					activeMeasure = msg->frame;
					measureBuffer = 0;
					for(i=0;i<activeMeasure;i++){
						uint8_t typeTemp = read_uint8_t(&(motesettings[TOS_NODE_ID-1][i]));
						if( typeTemp == RX ){
							measureBuffer++;
						}
						if( typeTemp == SSYN){
							measureBuffer = 0;
						}
					}
					measureBuffer = measureBuffer%NUMBER_OF_RX;
					call Alarm.startAt(startOfFrame,firetime);
          //call Leds.set(0);
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
			setLeds(ERROR_LATE_SEND_DONE_SIGNAL);
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