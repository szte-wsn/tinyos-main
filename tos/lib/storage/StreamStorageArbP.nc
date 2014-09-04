/*
* Copyright (c) 2009, University of Szeged
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

module StreamStorageArbP{
	provides {
		interface StreamStorageRead[uint8_t id];
		interface StreamStorageWrite[uint8_t id];
		interface StreamStorageErase[uint8_t id];
	}
	uses {
		interface StreamStorageRead as SubRead;
		interface StreamStorageWrite as SubWrite;
		interface StreamStorageErase as SubErase;
	}
}

implementation{
	uint8_t userid;
	
	command error_t StreamStorageRead.getMinAddress[uint8_t id](){
	    error_t error=call SubRead.getMinAddress(); 
	    if(error==SUCCESS)
			userid=id;
	    return error;
	}
	
	event void SubRead.getMinAddressDone(uint32_t addr,error_t error){
	    signal StreamStorageRead.getMinAddressDone[userid](addr,error);
	}
	
	command uint32_t StreamStorageRead.getMaxAddress[uint8_t id](){
	    return call SubRead.getMaxAddress();
	}
	
	command error_t StreamStorageRead.read[uint8_t id](uint32_t addr, void* buf, uint8_t  len){
	    error_t error=call SubRead.read(addr,buf,len); 
	    if(error==SUCCESS)
			userid=id;
	    return error;
	}
		
	event void SubRead.readDone(void* buf, uint8_t  len, error_t error){
	    signal StreamStorageRead.readDone[userid](buf,len, error);
	}
	
	
	command error_t StreamStorageWrite.appendWithID[uint8_t id](nx_uint8_t app_id, void* buf, uint16_t  len){
	    error_t error=call SubWrite.appendWithID(app_id,buf,len); 
	    if(error==SUCCESS)
			userid=id;
	    return error;
	}
	
	event void SubWrite.appendDoneWithID(void* buf, uint16_t  len, error_t error){
	    signal StreamStorageWrite.appendDoneWithID[userid](buf,len,error);
	}
	
	command error_t StreamStorageWrite.append[uint8_t id](void* buf, uint16_t  len){
	    error_t error=call SubWrite.append(buf,len); 
	    if(error==SUCCESS)
		userid=id;
	    return error;
	}
	
	event void SubWrite.appendDone(void* buf, uint16_t  len, error_t error){
	    signal StreamStorageWrite.appendDone[userid](buf,len,error);
	}
	
	command error_t StreamStorageWrite.sync[uint8_t id](){
	    error_t error=call SubWrite.sync(); 
	    if(error==SUCCESS)
		userid=id;
	    return error;
	}
	
	event void SubWrite.syncDone(error_t error){
	    signal StreamStorageWrite.syncDone[userid](error);
	}
	
	command error_t StreamStorageErase.erase[uint8_t id](){
	    error_t error=call SubErase.erase(); 
	    if(error==SUCCESS)
		userid=id;
	    return error;
	}
	
	event void SubErase.eraseDone(error_t error){
	    signal StreamStorageErase.eraseDone[userid](error);
	}
	
	default event void StreamStorageErase.eraseDone[uint8_t id](error_t error){}
	default event void StreamStorageRead.readDone[uint8_t id](void *buf, uint8_t len,error_t error){}
	default event void StreamStorageRead.getMinAddressDone[uint8_t id](uint32_t addr, error_t error){}
	default event void StreamStorageWrite.appendDone[uint8_t id](void *buf, uint16_t len, error_t error){}
	default event void StreamStorageWrite.appendDoneWithID[uint8_t id](void *buf, uint16_t len, error_t error){}
	default event void StreamStorageWrite.syncDone[uint8_t id](error_t error){}	
}

