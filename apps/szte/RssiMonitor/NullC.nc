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
	uses interface SplitControl;
	uses interface AMSend;
	uses interface Packet;
	uses interface Leds;
	#ifdef PLATFORM_UCMINI
	uses interface Notify<button_state_t>;
	#endif
	uses interface Timer<TMilli>;
}
implementation
{
	enum{
		BUFFER_LEN = 8192,
	};
	
	uint8_t buffer[BUFFER_LEN];
	uint16_t offset = 0;
	uint32_t time;
	message_t msg;
	
	task void startMeasure();
	task void sendData();
	
  event void Boot.booted() {
    call SplitControl.start();
  }
  
  event void SplitControl.startDone(error_t err){
		if( err != SUCCESS )
			call SplitControl.start();
		else{
			call Leds.led0On();
			call Timer.startOneShot(1000);
		}
	}
	
	event void Timer.fired(){
		#ifdef PLATFORM_UCMINI
		call Notify.enable();
		#else
		//TODO
		#endif
	}
	
	#ifdef PLATFORM_UCMINI
	event void Notify.notify(button_state_t val){
		if( val == BUTTON_RELEASED ){
			call Notify.disable();
			post startMeasure();
		}
	}
	#endif
	
	task void startMeasure(){
		time = 0;		
		call Leds.led1On();
		while( time == 0 ){
			time = call RssiMonitor.start(buffer, BUFFER_LEN);
		}
		offset = 0;
		call Leds.led1Off();
		call Leds.led2On();
		post sendData();
	}
	
	task void sendData(){
		uint8_t i;
		rssiMessage *payload = (rssiMessage*)call Packet.getPayload(&msg, sizeof(rssiMessage));
		call Leds.led3Toggle();
		payload->time = time;
		payload->index = offset;
		for( i=0; i<MSG_BUF_LEN; i++){
			payload->data[i] = buffer[offset+i];
		}
		if( call AMSend.send(AM_BROADCAST_ADDR, &msg, sizeof(rssiMessage)) != SUCCESS )
			post sendData();
	}
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if( error == SUCCESS )
			offset+= MSG_BUF_LEN;
		
		if(offset < BUFFER_LEN)
			post sendData();
		else{
			call Leds.led2Off();
			call Leds.led3Off();
			#ifdef PLATFORM_UCMINI
			call Notify.enable();
			#else
			//TODO
			#endif
		}
	}
	
	event void SplitControl.stopDone(error_t err){}
}

