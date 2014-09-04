/** Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Csepe Zoltan
*/

#include <Timer.h>
#include "TempStorage.h"
module TempWriteC {
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface LocalTime<TMilli>;
	uses interface Read<uint16_t> as Temperature;
	uses interface Read<uint16_t> as Humidity;
	
	uses interface Read<uint16_t> as VoltageRead;
	uses interface LogWrite;
	uses interface Receive;
	uses interface AMSend;
	uses interface Packet;
	uses interface AMPacket;
	uses interface PacketAcknowledgements;
	uses interface LogRead;
	uses interface SplitControl as RadioControl;
	uses interface LowPowerListening as LPL;
	
	uses interface DiagMsg;
}
implementation {
	enum{
		CMD_MEASURE = 1,
		CMD_DOWNLOAD = 2,
		CMD_ERASE = 3,
		CMD_BLINK = 4,
	};
	
	typedef nx_struct logentry_t {
		nx_uint16_t humidity;
		nx_uint16_t counter;
		nx_uint32_t time;
		nx_uint16_t temp;
	} logentry_t;
	bool m_busy = TRUE;
	uint16_t c=1;
	uint16_t set=0;
	uint16_t set2=1;
	uint16_t pctime_eleje;
	uint16_t pctime_vege;
	uint32_t seged;
	logentry_t m_entry;
	message_t pkt;
	bool busy=FALSE;
	uint16_t counter=0;
	uint32_t pctime;
	uint32_t lastTime=0;
	uint32_t logReadPos=SEEK_BEGINNING;
	am_addr_t controller = AM_BROADCAST_ADDR;


	event void Boot.booted() {
		if( call DiagMsg.record() ){
			call DiagMsg.str("booted");
			call DiagMsg.send();
		}
		call Leds.led2On();
		call RadioControl.start();
	}

	event void RadioControl.startDone(error_t err){
		if (err == SUCCESS){
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI_WRITE);
			call Leds.led2Off();
		}
		else {
			call RadioControl.start();
		}
	}
	

	event void Timer0.fired() {
		if( call DiagMsg.record() ){
			call DiagMsg.str("timer");
			call DiagMsg.uint8(c);
			call DiagMsg.uint8(set2);
			call DiagMsg.send();
		}
		if (c==CMD_MEASURE) {
			call Temperature.read();
		} else if (c==CMD_DOWNLOAD) {
			call LogRead.read(&m_entry, sizeof(logentry_t));
			call Leds.led0On();
		} else if (c==CMD_ERASE) {
			if (call LogWrite.erase() == SUCCESS) {
				call Leds.led0On();
			}
		} else if (c==CMD_BLINK){
			call Leds.led2Toggle();
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI_WRITE);
		}
	}
	
	event void Temperature.readDone(error_t result, uint16_t data) {
		counter++;
		//call Leds.led3On();
		m_entry.time=call LocalTime.get();
		m_entry.counter=counter;
		m_entry.temp=data;
		call Humidity.read();
	}

	event void Humidity.readDone(error_t result, uint16_t data) {
		m_entry.humidity=data;
		call LogWrite.append(&m_entry, sizeof(logentry_t));
	}

	event void VoltageRead.readDone(error_t result, uint16_t data) {
		if(result==SUCCESS){
			m_entry.temp=data;
			m_entry.time=call LocalTime.get();
			m_entry.humidity=data;
			m_entry.counter=counter;
			if(!busy){
				BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
				btrpkt->temperature = m_entry.temp;
				btrpkt->time = m_entry.time;
				btrpkt->counter=m_entry.counter;
				btrpkt->humidity=m_entry.humidity;
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg))==SUCCESS){
					busy = TRUE;
				} else {
					busy=FALSE;
				}
				call Leds.led0Off();
			}
		}else{
			call Leds.led0Toggle();
		}
	}

	event void LogWrite.appendDone(void* buf, storage_len_t len, bool recordsLost, error_t err) {
    	if (err==SUCCESS){
				call Leds.led3Off();
			} else {
				call Leds.led3Toggle();
			}
  	}
	
	event message_t* Receive.receive(message_t* msgPtr, void* payload, uint8_t len){
		if( call DiagMsg.record() ){
			call DiagMsg.str("rec");
			call DiagMsg.uint16(call AMPacket.source(msgPtr));
			call DiagMsg.send();
		}
		call Leds.led1On();
		if(len==sizeof(ControlMsg)){
			ControlMsg* btrpkt = (ControlMsg*)payload;
			controller = call AMPacket.source(msgPtr);
			if( call DiagMsg.record() ){
				call DiagMsg.str("rec");
				call DiagMsg.uint8(btrpkt->control);
				call DiagMsg.send();
			}
			if (btrpkt->control==CMD_DOWNLOAD || btrpkt->control==CMD_ERASE || btrpkt->control == CMD_BLINK ){
				c=btrpkt->control;
				pctime=btrpkt->time;
				call Leds.led3On();
				//counter++;
				m_entry.time=call LocalTime.get();
				pctime_eleje=(uint16_t)(pctime/100000);
				m_entry.temp=pctime_eleje;
				seged=pctime_eleje*100000;
				pctime_vege=(uint16_t)(pctime%seged);
				m_entry.humidity=pctime_vege;
				if ((pctime%seged)>0xFFFF){
					m_entry.counter=0x0000;
				}else{
					m_entry.counter=0xFFFF;
				}
				call LogWrite.append(&m_entry, sizeof(logentry_t));
				call Timer0.startOneShot(TIMER_PERIOD_MILLI_READ);
				//call Leds.led1Off();
			}
		}
		call Leds.led1Off();
		return msgPtr;
	}

	event void LogRead.readDone(void* buf, storage_len_t len, error_t err) {
		if(err==SUCCESS && !busy){
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof(BlinkToRadioMsg)));
			if( len >= sizeof(m_entry )){
				btrpkt->temperature = m_entry.temp;
				btrpkt->time = m_entry.time;
				btrpkt->counter=m_entry.counter;
				btrpkt->humidity=m_entry.humidity;
			} else {
				btrpkt->temperature = END_VALUE;
				btrpkt->time = END_VALUE;
				btrpkt->counter=END_VALUE;
				btrpkt->humidity=END_VALUE;
				c = CMD_MEASURE;
			}
			call PacketAcknowledgements.requestAck(&pkt);
			if (call AMSend.send(controller, &pkt, sizeof(BlinkToRadioMsg))==SUCCESS){
				busy = TRUE;
			} else {
				busy=FALSE;
			}
			call Leds.led1On();	
			call Leds.led0Off();
		}else{
			call Timer0.startOneShot(TIMER_PERIOD_MILLI_READ);
		}
		
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if( error == SUCCESS && call PacketAcknowledgements.wasAcked(msg) ){
			busy = FALSE;
			call Leds.led1Off();
			if( c == CMD_DOWNLOAD )
				call LogRead.read(&m_entry, sizeof(logentry_t));
			else if ( c == CMD_MEASURE ) 
				call Timer0.startPeriodic(TIMER_PERIOD_MILLI_WRITE); //restart timer
		} else {
			call PacketAcknowledgements.requestAck(&pkt);
			if (call AMSend.send(controller, &pkt, sizeof(BlinkToRadioMsg))!=SUCCESS)
				busy = FALSE;
		}
	}

	event void LogWrite.eraseDone(error_t err) {
		if (err==SUCCESS){
			call Leds.led0Off();
			c=CMD_MEASURE;
			counter=0;
			call Timer0.startOneShot(TIMER_PERIOD_MILLI_WRITE);
		} else {
			if (call LogWrite.erase() == SUCCESS) {
				call Leds.led0On();
			}
		}
	}
	event void LogWrite.syncDone(error_t err) {}
	event void RadioControl.stopDone(error_t err){}
	event void LogRead.seekDone(error_t err) {}

}





