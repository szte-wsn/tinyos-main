/*
* Copyright (c) 2000-2005 The Regents of the University  of California.  
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
*   notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright
*   notice, this list of conditions and the following disclaimer in the
*   documentation and/or other materials provided with the
*   distribution.
* - Neither the name of the University of California nor the names of
*   its contributors may be used to endorse or promote products derived
*   from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
* THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*
* Copyright (c) 2002-2005 Intel Corporation
* All rights reserved.
*
* This file is distributed under the terms in the attached INTEL-LICENSE     
* file. If you do not find these files, copies can be found by writing to
* Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
* 94704.  Attention:  Intel License Inquiry.
*/

/**
* Null is an empty skeleton application.  It is useful to test that the
* build environment is functional in its most minimal sense, i.e., you
* can correctly compile an application. It is also useful to test the
* minimum power consumption of a node when it has absolutely no 
* interrupts or resources active.
*
* @author Cory Sharp <cssharp@eecs.berkeley.edu>
* @date February 4, 2006
*/

#include "UserButton.h"

module NullC @safe()
{
	uses interface Boot;
	uses interface RssiMonitor;
	uses interface AtmelRadioTest;
	uses interface SplitControl;
	uses interface AMSend;
  uses interface AMSend as RssiDone;
  uses interface AMPacket;
	uses interface Packet;
  uses interface PacketAcknowledgements;
	uses interface Receive;
	uses interface Leds;
	uses interface Timer<TMilli>;
}
implementation
{
	enum{
		BUFFER_LEN = 8192,
	};
	
	enum{
		S_IDLE,
		S_CW_WAIT,
		S_CW,
		S_MEASURE_WAIT,
		S_MEASURE,
		S_SEND_WAIT,
		S_SEND,
	};
	
	uint8_t buffer[BUFFER_LEN];
	uint8_t cwMode;
	uint16_t offset = 0;
	uint32_t time;
	uint32_t waitAfter;
	uint8_t state = S_IDLE;
  uint16_t controller;
	
	message_t msg;
	
	task void sendData();
	
	event void Boot.booted() {
		call Leds.set(0xff);
		call SplitControl.start();
	}
	
	event void SplitControl.startDone(error_t err){
		if( err != SUCCESS )
			call SplitControl.start();
		else {
			state = S_IDLE;
			call Leds.set(0);
		}
	}
	
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
		if( state == S_IDLE ){
			commandMessage_t* cmd = (commandMessage_t*)payload;
      controller = call AMPacket.source(bufPtr);
			if( cmd->cw[0] == TOS_NODE_ID || cmd->cw[1] == TOS_NODE_ID ){
				call Leds.led0On();
				state = S_CW_WAIT;
				waitAfter = cmd->cwLength;
				call SplitControl.stop();
				if( cmd->cw[0] == TOS_NODE_ID ){
					cwMode = cmd->cwMode[0];
				} else if( cmd->cw[1] == TOS_NODE_ID ){
					cwMode = cmd->cwMode[1];
				}
				call Timer.startOneShot(cmd->waitBeforeCw);
			} else {
				call Leds.led1On();
				state = S_MEASURE_WAIT;
				waitAfter = cmd->cwLength + cmd->waitBeforeCw - cmd->waitBeforeMeasure;
				call Timer.startOneShot(cmd->waitBeforeMeasure);
			}
		}
		return bufPtr;
	}
	
	event void Timer.fired(){
		if( state == S_CW_WAIT ){
			state = S_CW;
			call AtmelRadioTest.startCWTest(0xff, 0xff, cwMode);
			call Leds.led2On();
			call Timer.startOneShot(waitAfter);
		} else if( state == S_CW ){
			call AtmelRadioTest.stopTest();
			call Leds.led2Off();
			call SplitControl.start();
		} else if( state == S_MEASURE_WAIT ){
			state = S_MEASURE;
			call Leds.led2On();
			time = call RssiMonitor.start(buffer, BUFFER_LEN);
			call Leds.led2Off();
			call Timer.startOneShot(waitAfter);
			state = S_SEND_WAIT;
		} else { //S_SEND_WAIT
			state = S_SEND;
			offset = 0;
			post sendData();
		}
	}
	
	
	task void sendData(){
		uint8_t i;
		rssiMessage_t *payload = (rssiMessage_t*)call Packet.getPayload(&msg, sizeof(rssiMessage_t));
		call Leds.led3Toggle();
		payload->index = offset;
		for( i=0; i<MSG_BUF_LEN; i++){
			payload->data[i] = buffer[offset+i];
		}
		call PacketAcknowledgements.requestAck(&msg);
		if( call AMSend.send(controller, &msg, sizeof(rssiMessage_t)) != SUCCESS )
			post sendData();
	}
	
	task void sendDone(){
    rssiDataDone_t *payload = (rssiDataDone_t*)call Packet.getPayload(&msg, sizeof(rssiDataDone_t));
    call Leds.led3Toggle();
    payload->time = time;
    call PacketAcknowledgements.requestAck(&msg);
    if( call RssiDone.send(controller, &msg, sizeof(rssiDataDone_t)) != SUCCESS )
      post sendDone();
  }
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if( error == SUCCESS && call PacketAcknowledgements.wasAcked(bufPtr) )
			offset+= MSG_BUF_LEN;
		
		if(offset < BUFFER_LEN){
			post sendData();
    }else {
      post sendDone();
    }
	}
	
	event void RssiDone.sendDone(message_t* bufPtr, error_t error) {
    if( error == SUCCESS && call PacketAcknowledgements.wasAcked(bufPtr) ){
      state = S_IDLE;
      call Leds.led1Off();
      call Leds.led3Off();
    } else {
      post sendDone();
    }
  }
	
	event void SplitControl.stopDone(error_t err){}
}

