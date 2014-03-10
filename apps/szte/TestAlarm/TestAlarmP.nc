#include "TestAlarm.h"

#define NUMBER_OF_MEASURES 3

module TestAlarmP{
	uses interface Boot;
	uses interface AMSend;
	uses interface SplitControl;
	uses interface Leds;
	uses interface DiagMsg;
	//uses interface LocalTime<TRadio> as LocalTime;
	uses interface Alarm<T62khz, uint32_t> as Alarm;
	uses interface Packet;
	uses interface Receive;
	uses interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
}
implementation{

	uint32_t sender_wait[NUMBER_OF_MEASURES];
	uint32_t sender_send[NUMBER_OF_MEASURES];
	uint32_t receiver_wait[NUMBER_OF_MEASURES];
	uint8_t num_of_measures = 0; //how many measures was configured
	bool sender[NUMBER_OF_MEASURES]; //TRUE - if the mote is sender during the Ti. measure
	bool receiver[NUMBER_OF_MEASURES]; //TRUE - if the mote is receiver during the Ti. measure
	message_t packet;
	
	event void Boot.booted(){
		call SplitControl.start();
	}
	
	event void SplitControl.startDone(error_t error){
	}

	event void SplitControl.stopDone(error_t error){}
	event void AMSend.sendDone(message_t* msg, error_t error) {
		
	}

	
	async event void Alarm.fired(){
		uzenet_t* rcm = (uzenet_t*)call Packet.getPayload(&packet, sizeof(uzenet_t));
		rcm -> funcid = 0xFA;
		//rcm -> ido = call LocalTime.get();
		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(uzenet_t)) == SUCCESS) {
			call Leds.led1Toggle();
      	}
	}

	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
			config_msg_t* msg = (config_msg_t*)payload;
			if(msg->T1sender_send > 0){
				num_of_measures++;
				sender[0]=(TOS_NODE_ID == msg->T1sender1ID || TOS_NODE_ID == msg->T1sender2ID);
				receiver[0] = !sender[0];
				//tovább fel kell dolgoznom az üzeneteket, majd megcsinálni, hogy az 
				//idozitések rendben legyenek, és hogy a méréseket sorban egymás után végezze
			}

			if(TOS_NODE_ID == ){
					sender = TRUE;
					receiver = FALSE;
					call Leds.set(7);
					if(call PacketTimeStampRadio.isValid(bufPtr)){
					waittime = bufPtr->data[len-1-15]; 
					waittime |= (uint32_t)bufPtr->data[len-1-14]<<8;
					waittime |= (uint32_t)bufPtr->data[len-1-13]<<16;
					waittime |= (uint32_t)bufPtr->data[len-1-12]<<24;
					sendtime = bufPtr->data[len-1-11]; 
					sendtime |= (uint32_t)bufPtr->data[len-1-10]<<8;
					sendtime |= (uint32_t)bufPtr->data[len-1-9]<<16;
					sendtime |= (uint32_t)bufPtr->data[len-1-8]<<24;
					call Alarm.startAt(call PacketTimeStampRadio.timestamp(bufPtr),waittime);
					}
			}
			for(i=0;i<receivers;i++){
				if(TOS_NODE_ID == bufPtr->data[i+2+senders]){
					receiver = TRUE;
					sender = FALSE;
					call Leds.set(6);
					if(call PacketTimeStampRadio.isValid(bufPtr)){
					waittime = bufPtr->data[len-1-7]; 
					waittime |= (uint32_t)bufPtr->data[len-1-6]<<8;
					waittime |= (uint32_t)bufPtr->data[len-1-5]<<16;
					waittime |= (uint32_t)bufPtr->data[len-1-4]<<24;
					sendtime = bufPtr->data[len-1-3]; 
					sendtime |= (uint32_t)bufPtr->data[len-1-2]<<8;
					sendtime |= (uint32_t)bufPtr->data[len-1-1]<<16;
					sendtime |= (uint32_t)bufPtr->data[len-1]<<24;
					call Alarm.startAt(call PacketTimeStampRadio.timestamp(bufPtr),waittime);
					}
				}
			}
			
			
		}
		return bufPtr;
	}

}
