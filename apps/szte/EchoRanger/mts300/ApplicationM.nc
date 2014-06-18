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
		interface StreamStorageWrite;
		interface Boot;
		interface Leds;
		interface LocalTime<TMilli>;
		interface Timer<TMilli> as SensorTimer; 
		interface Read<echorange_t*>; 
		interface Get<uint16_t*> as LastBuffer;
		interface Get<echorange_t*> as LastRange;
		interface Set<uint8_t> as SetGain;
		interface Set<uint8_t> as SetWait;
		interface Command;
	}
}

implementation{
	
	uint8_t counter=0;

	event void Boot.booted(){
		uint32_t period=(uint32_t)SAMP_T*1024*60;
		call StdControl.start();
		call SensorTimer.startPeriodicAt(call SensorTimer.getNow()-period+(uint32_t)WAIT_AFTER_START*1024,period);	
	}
	
	event void SensorTimer.fired(){
		call Read.read();
	}
	
	event void Read.readDone(error_t result, echorange_t* range){
		if(result==SUCCESS){
			call StreamStorageWrite.appendWithID(0x00,range, sizeof(echorange_t));
		} else{
			call Leds.led1Toggle();
		}
	}
	
	event void StreamStorageWrite.appendDoneWithID(void* buf, uint16_t  len, error_t error){
		if((SAVE_WAVE!=0)&&len==sizeof(echorange_t)){
			counter++;
			if(counter==SAVE_WAVE){
				uint16_t* buffer=call LastBuffer.get();
				call StreamStorageWrite.appendWithID(0x11,buffer, sizeof(uint16_t)*ECHORANGER_BUFFER);
				counter=0;
			}
		}
	}	
	
	event void Command.newCommand(uint32_t id){
		if((id&0xff)==128){
		    call SetGain.set((id>>8)&0xff);
		    call Command.sendData(id);	
		}else if((id&0xff)==120){
		    call SetWait.set((id>>8)&0xff);
		    call Command.sendData(id);	
		}else if(id==1){
		    uint32_t period=(uint32_t)SAMP_T*1024*60;
		    call SensorTimer.startPeriodicAt(call SensorTimer.getNow()-period+(uint32_t)3*1024,period);	
		    call Command.sendData(id);
		}
	}
	
	event void StreamStorageWrite.appendDone(void* buf, uint16_t  len, error_t error){}
	event void StreamStorageWrite.syncDone(error_t error){}
}
