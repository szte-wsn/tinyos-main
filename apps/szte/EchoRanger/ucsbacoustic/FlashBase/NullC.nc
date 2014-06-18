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
#include "EchoRanger.h"
module NullC @safe()
{
	uses interface Boot;
	uses interface SplitControl;
	uses interface Resource;
	uses interface FramedRead;
	uses interface Timer<TMilli>;
	uses interface Notify<uint32_t> as DownloadDone;
	uses interface StreamDownloaderInfo;
	uses interface SplitControl as StorageControl;
	uses interface DiagMsg;
}
implementation
{
	uint8_t buffer[3000U];
	uint32_t nextAddress;
	
	event void Boot.booted() {
		if(call DiagMsg.record()){
			call DiagMsg.str("B");
			call DiagMsg.send();
		}
		call StorageControl.start();
	}
	
	event void StorageControl.startDone(error_t err){
		call SplitControl.start();
	}
	
	event void DownloadDone.notify(uint32_t endAddress){
		if(call DiagMsg.record()){
			call DiagMsg.str("DD");
			call DiagMsg.uint32(endAddress);
			call DiagMsg.send();
		}
		if(call DiagMsg.record()){
			call DiagMsg.str("INFO");
			call DiagMsg.uint16(call StreamDownloaderInfo.getNodeId());
			call DiagMsg.uint32(call StreamDownloaderInfo.getOffset());
			call DiagMsg.uint32(call StreamDownloaderInfo.getSkew());
			call DiagMsg.send();
		}
		call Resource.request();
	}
	
	event void Timer.fired(){
		call FramedRead.read(nextAddress, buffer, 3000U);
	}
	
	event void Resource.granted(){
		if(call DiagMsg.record()){
			call DiagMsg.str("RESOURCE");
			call DiagMsg.send();
		}
		if( call SplitControl.stop() == EALREADY )
			call FramedRead.read(nextAddress, buffer, 3000U);
	}
	
	event void SplitControl.stopDone(error_t err){
		call FramedRead.getMinAddress();
	}
	
	event void FramedRead.getMinAddressDone(uint32_t addr,error_t error){
		if(call DiagMsg.record()){
			call DiagMsg.str("GMD");
			call DiagMsg.send();
		}
		if( error == SUCCESS )
			call FramedRead.read(addr, buffer, 3000U);
	}
	
	event void FramedRead.readDone(error_t error, void* buf, uint16_t bufferlen, uint32_t startAddress, uint16_t frameLength, uint32_t nextReadAddress){
		if(error != SUCCESS){
			if(call DiagMsg.record()){
				call DiagMsg.str("RE");
				call DiagMsg.uint8(error);
				call DiagMsg.send();
			}
		} else {
			if(frameLength == sizeof(echorange_t)+1 && *((uint8_t*)buf) == 0 ){
				echorange_t* data = (echorange_t*)(buf+1);
				if(call DiagMsg.record()){
					call DiagMsg.chr('E');
					call DiagMsg.uint16(data->seqno);
					call DiagMsg.uint32(data->timestamp);
					call DiagMsg.uint32(call StreamDownloaderInfo.convertTimeStamp(data->timestamp, FALSE));
					call DiagMsg.uint32(call StreamDownloaderInfo.convertTimeStampToRelativeTime(data->timestamp));
					call DiagMsg.int16(data->temperature);
					call DiagMsg.uint16(data->average);
					call DiagMsg.uint16(data->range0);
					call DiagMsg.int16(data->score0);
					call DiagMsg.uint16(data->range1);
					call DiagMsg.int16(data->score1);
					call DiagMsg.uint16(data->range2);
					call DiagMsg.int16(data->score2);
					call DiagMsg.send();
				}
			} else if(frameLength == sizeof(uint16_t)*ECHORANGER_BUFFER + 1 && *((uint8_t*)buf) == 0x11){
				if(call DiagMsg.record()){
					call DiagMsg.str("WAVE");
					call DiagMsg.send();
				}
			} else {
				if(call DiagMsg.record()){
					call DiagMsg.str("REL");
					call DiagMsg.uint16(frameLength);
					call DiagMsg.send();
				}
			}
		}
		
		if(call DiagMsg.record()){
			call DiagMsg.uint16(frameLength);
			call DiagMsg.uint32(startAddress);
			call DiagMsg.uint32(nextReadAddress);
			call DiagMsg.send();
		}
		nextAddress = nextReadAddress;
		call Timer.startOneShot(10);
	}
	
	event void SplitControl.startDone(error_t err){}
	event void StorageControl.stopDone(error_t err){}
}

