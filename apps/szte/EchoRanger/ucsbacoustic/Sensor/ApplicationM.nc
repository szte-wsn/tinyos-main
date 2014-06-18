/*
* Copyright (c) 2010, University of Szeged
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
* Author:Andras Biro
*/

#include "EchoRanger.h"
#ifndef SAMP_T
	#define SAMP_T 1
#endif
#ifndef SAVE_WAVE
	#define SAVE_WAVE 1
#endif
#ifndef WAIT_AFTER_START
	#define WAIT_AFTER_START 30
#endif

module ApplicationM{
	uses {
		interface StdControl;
		interface SplitControl;
		interface StreamStorageWrite;
		interface StreamStorageErase;
		interface Boot;
		interface Leds;
		interface LocalTime<TMilli>;
		interface Timer<TMilli> as SensorTimer; 
		interface Read<echorange_t*>; 
		interface ReadRef<uint16_t> as LastBuffer;
		interface Set<uint8_t> as SetFineGain;
		interface Set<uint8_t> as SetCoarseGain;
		interface Set<uint8_t> as SetWait;
		interface Command;
		interface DiagMsg;
	}
}

implementation{
	
	uint8_t counter=0;
	
	uint16_t buffer[ECHORANGER_BUFFER];

	event void Boot.booted(){
		if(TOS_NODE_ID==9999){
			call SensorTimer.startOneShot(2000);
		}else{
			call SplitControl.start();
		}
	}
	
	event void SplitControl.startDone(error_t err){
		uint32_t period=(uint32_t)SAMP_T*1024*60;
		call StdControl.start();
		call SensorTimer.startPeriodicAt(call SensorTimer.getNow()-period+(uint32_t)WAIT_AFTER_START*1024,period);
	}
	
	event void SensorTimer.fired(){
		if(TOS_NODE_ID==9999){
			error_t err = call StreamStorageErase.erase();
			if(call DiagMsg.record()){
				call DiagMsg.str("erase");
				call DiagMsg.uint8(err);
				call DiagMsg.send();
			}
		}else{
			error_t err =	call Read.read();
			if(call DiagMsg.record()){
				call DiagMsg.str("read");
				call DiagMsg.uint8(err);
				call DiagMsg.send();
			}
		}
	}
	
	event void Read.readDone(error_t result, echorange_t* range){
		if(call DiagMsg.record()){
			call DiagMsg.str("App readDone");
			call DiagMsg.uint8(result);
			call DiagMsg.send();
		}
		
		if(result==SUCCESS){
			call StreamStorageWrite.appendWithID(0x00,range, sizeof(echorange_t));
		} else{
			call Leds.led1Toggle();
		}
	}
	
	event void StreamStorageWrite.appendDoneWithID(void* buf, uint16_t  len, error_t error){
		if(call DiagMsg.record()){
			call DiagMsg.str("App writeDone");
			call DiagMsg.uint8(error);
			call DiagMsg.send();
		}
		if((SAVE_WAVE!=0)&&len==sizeof(echorange_t)){
			counter++;
			if(counter==SAVE_WAVE){
				call LastBuffer.read(buffer);
				counter=0;
			}
		}
	}	
	
	event void LastBuffer.readDone(error_t err, uint16_t* readbuffer){
		call StreamStorageWrite.appendWithID(0x11,readbuffer, sizeof(uint16_t)*ECHORANGER_BUFFER);
	}
	
	event void Command.newCommand(uint32_t id){
		if((id&0xff)==CMD_SETWAIT){
		    call SetWait.set((id>>8)&0xff);
		    call Command.sendData(id);	
		}else if(id==CMD_MEASNOW){
		    uint32_t period=(uint32_t)SAMP_T*1024*60;
		    call SensorTimer.startPeriodicAt(call SensorTimer.getNow()-period+(uint32_t)3*1024,period);	
		    call Command.sendData(id);
		} else if((id&0xff)==CMD_SETGAIN_DUAL){
			call SetCoarseGain.set((id>>8)&0xff);
			call SetFineGain.set((id>>16)&0xff);
			call Command.sendData(id);
		}
	}
	
	event void StreamStorageErase.eraseDone(error_t err){
		call Leds.set(0xff);
		if(call DiagMsg.record()){
			call DiagMsg.str("App eraseDone");
			call DiagMsg.uint8(err);
			call DiagMsg.send();
		}
	}
	
	event void SplitControl.stopDone(error_t err){}
	event void StreamStorageWrite.appendDone(void* buf, uint16_t  len, error_t error){}
	event void StreamStorageWrite.syncDone(error_t error){}
}
