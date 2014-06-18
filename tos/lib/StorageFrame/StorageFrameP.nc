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
generic module StorageFrameP(){
	provides interface StreamStorageWrite as FramedWrite;
    provides interface Debug;
    
	uses interface StreamStorageWrite;
	uses interface Resource;
}
implementation{
	enum {
		FRAMEBYTE=0x5e,
		ESCAPEBYTE=0x5d,
		XORESCAPEBYTE=0x20,
		REQ_APPEND,
		REQ_APPENDWITHID,
		REQ_SYNC,
		REQ_GETMINADDRESS,
		REQ_READ,
	};

	void* bufptr;
	uint16_t length;
	uint32_t addr;
	int16_t current;
	nx_uint16_t buffer;
	uint8_t request;
    
    command uint8_t Debug.getStatus(){
      return 0;
    }
    command bool Debug.isResourceOwned(){
      return call Resource.isOwner();
    }
    command void Debug.resetStatus(){}
    command void Debug.releaseResource(){
      call Resource.release();
    }
	
	event void Resource.granted(){
	  error_t error=SUCCESS;//to avoid a nesc warning
	  switch(request){
	    case REQ_APPENDWITHID:{
	      error=call StreamStorageWrite.append(&buffer, 2);//frame and id
	    }break;
	    case REQ_APPEND:{
	      error=call StreamStorageWrite.append(&buffer, 1);//frame
	    }break;
	    case REQ_SYNC:{
	      error=call StreamStorageWrite.sync(); 
	    }break;
	  }
	  if(error!=SUCCESS){
	    call Resource.release();
	    switch(request){
	      case REQ_APPENDWITHID:{
		signal FramedWrite.appendDoneWithID(bufptr, length, error);
	      }break;
	      case REQ_APPEND:{
		signal FramedWrite.appendDone(bufptr, length, error);
	      }break;
	      case REQ_SYNC:{
		signal FramedWrite.syncDone(error);
	      }break;
	    }
	  }
	}

	command error_t FramedWrite.appendWithID(nx_uint8_t id, void *buf, uint16_t len){
	  if(call Resource.request()==SUCCESS){
		  length=len;
		  current=-1;
		  bufptr=buf;
		  buffer=FRAMEBYTE<<8;
		  buffer+=id;
		  request=REQ_APPENDWITHID;
		  return SUCCESS;
	  } else
		  return EBUSY;
	}

	command error_t FramedWrite.append(void *buf, uint16_t len){
	  if(call Resource.request()==SUCCESS){
		length=len;
		current=-1;
		buffer=FRAMEBYTE<<8;
		bufptr=buf;
		request=REQ_APPEND;
		return SUCCESS;
	  } else
	      return EBUSY;
	  
	}

	event void StreamStorageWrite.appendDone(void *buf, uint16_t len, error_t error){
	  if(error==SUCCESS){
		current++;
// 		if(current==-1){//ID
// 			if(writeid==ESCAPEBYTE||writeid==FRAMEBYTE){
// 				buffer=ESCAPEBYTE<<8;
// 				buffer+=(writeid^XORESCAPEBYTE);
// 				call StreamStorageWrite.append(&buffer, 2);
// 			} else{
// 				call StreamStorageWrite.append(&writeid, 1);
// 			}
// 		} else 
		if(current<length){
			if(*((uint8_t* )(bufptr+current))==FRAMEBYTE||*((uint8_t* )(bufptr+current))==ESCAPEBYTE){
				buffer=ESCAPEBYTE<<8;
				buffer+=*((uint8_t* )(bufptr+current))^XORESCAPEBYTE;
				call StreamStorageWrite.append(&buffer, 2);	
			} else {
				uint16_t i=0;
				while(i<250&&i+current<length&&*((uint8_t* )(bufptr+current+i))!=FRAMEBYTE&&*((uint8_t* )(bufptr+current+i))!=ESCAPEBYTE){
					i++;
				}
				call StreamStorageWrite.append(bufptr+current, i);
				current+=i-1;
			}
		} else if(current==length){//closing frame
			buffer=FRAMEBYTE<<8;
			call StreamStorageWrite.append(&buffer, 1);	
		} else {
			call Resource.release();
			if(request==REQ_APPEND)
				signal FramedWrite.appendDone(bufptr, length, SUCCESS);
			else
				signal FramedWrite.appendDoneWithID(bufptr, length, SUCCESS);
		}
	  } else{
		call Resource.release();
		if(request==REQ_APPEND)
			signal FramedWrite.appendDone(bufptr, length, error);
		else
			signal FramedWrite.appendDoneWithID(bufptr, length, error);
	  }
	}

	event void StreamStorageWrite.appendDoneWithID(void *buf, uint16_t len, error_t error){}//we never called appendWithID


//from here, we're just forwarding the calls and signals
	command error_t FramedWrite.sync(){
	  if(call Resource.request()==SUCCESS){
	    request=REQ_SYNC;
	    return SUCCESS;
	  } else
		return EBUSY;
	}

	event void StreamStorageWrite.syncDone(error_t error){
	  call Resource.release();
	  signal FramedWrite.syncDone(error);
	}

}