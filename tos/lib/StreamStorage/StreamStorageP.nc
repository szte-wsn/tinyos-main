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
//command to watch the debug lines:
//java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB1:iris
//#define DEBUG
#ifdef DEBUG
	#include "printf.h"
#endif
module StreamStorageP{
	provides {
		interface StreamStorageRead;
		interface StreamStorageWrite;
		interface StreamStorageErase;
		interface SplitControl;
		interface Debug;
	}
	uses {
		interface LogRead;
		interface LogWrite;
	}
}
implementation{
	enum {
		UNINIT=0,
		NORMAL,
		INIT_START,
		INIT,
		INIT_STEP,
		READ_PENDING_SEEK,
		READ_PENDING_SEEK_STEP_B,
		READ_PENDING_SEEK_STEP_F,
		READ_PENDING_DATA1,
		READ_PENDING_DATA2,
		READ_PENDING_DATA3,
		WRITE_PENDING_ID,
		WRITE_PENDING_DATA1,
		WRITE_PENDING_DATA2,
		WRITE_PENDING_METADATA,
		WRITE_PENDING_METADATA_ID_UNWRITTEN,
		ERASE_PENDING,
		ERASE_PENDING_UNINIT,
		SYNC_PENDING,
		GET_MIN,
		
		//AT45DB specific settings
		PAGE_SIZE=254,
		ERASE_SIZE=PAGE_SIZE,
		FIRST_DATA=254,
	};
	
	void *writebuffer, *readbuffer;
	uint8_t writelength, firstwritelength, readlength, readfirstlength;
	nx_uint8_t write_id;
	uint32_t buffer;
	/*
	 * current_addr: We already written current_addr bytes into the flash (with id, but without metadata)
	 * this should be always correct (even after sync or reset)
	 * we write this number to the first bytes of every page (on the first page, it's 0)
	 */
	nx_uint32_t current_addr;
	uint8_t status=UNINIT;
	uint32_t last_page;
	uint16_t circled=0;
	uint16_t PAGES;
	struct{
		uint32_t streamAddress;
		storage_cookie_t logAddress;
		bool success;
	} addressTranslation;
	
	struct{
		uint32_t address;
		bool valid;
	} minAddress;
	
//Debug
	command uint8_t Debug.getStatus(){
		return status;
	}
	
    command bool Debug.isResourceOwned(){
      return FALSE;
    }
    
    command void Debug.resetStatus(){
      status=NORMAL;
    }
    command void Debug.releaseResource(){}
	
//Start/Stop
	
	command error_t SplitControl.start(){
		if(status!=UNINIT)
			return EALREADY;
		status=INIT_START;
		#ifdef DEBUG
			printf("Start; ");
		#endif
		PAGES=call LogRead.getSize()/PAGE_SIZE;
		#ifdef DEBUG
			printf(" volume size=%ld; pages=%u; ",call LogRead.getSize(),PAGES);
			printfflush();
		#endif
		addressTranslation.success=FALSE;	
		call LogRead.seek(SEEK_BEGINNING);
		return SUCCESS;	
	}

	task void signalStopDoneSucces(){
		signal SplitControl.stopDone(SUCCESS);
	}

	command error_t SplitControl.stop(){
		status=UNINIT;
		post signalStopDoneSucces();
		return SUCCESS;
	}
		
//Erease

	command error_t StreamStorageErase.erase(){
		if(status!=NORMAL&&status!=UNINIT){
			return EBUSY;
		} else {
			if(status==NORMAL)
				status=ERASE_PENDING;
			else
				status=ERASE_PENDING_UNINIT;
			call LogWrite.erase();	
			return SUCCESS;
		}
	}
	
	event void LogWrite.eraseDone(error_t error){
		#ifdef DEBUG
			printf("Erase done\n");
			printfflush();
		#endif	
		if(error==SUCCESS){
			current_addr=0;
			minAddress.address=0;
		}
		if(status==ERASE_PENDING)
			status=NORMAL;
		else
			status=UNINIT;	
		signal StreamStorageErase.eraseDone(error);
	}

//Write
	command error_t StreamStorageWrite.append(void *buf, uint16_t len){
		if(status!=NORMAL){
			if(status==UNINIT)
				return EOFF;
			else
				return EBUSY;
		} else if(len>PAGE_SIZE-sizeof(current_addr)){
			return EINVAL;
		}else{
			error_t err;
			uint32_t offset=call LogWrite.currentOffset();
			status=WRITE_PENDING_DATA1;
			writebuffer=buf;
			writelength=len;
			write_id=0;			
			
			if(((offset/PAGE_SIZE)<((offset+len-1)/PAGE_SIZE))||(offset%PAGE_SIZE)==0||((offset/PAGE_SIZE)%PAGES==0&&(offset%PAGE_SIZE+len+circled)>=PAGE_SIZE)){//data is overlapping to the next page, or we're on the first byte of the page
				firstwritelength=(PAGE_SIZE-(offset%PAGE_SIZE))%PAGE_SIZE;
				if((offset/PAGE_SIZE)%PAGES==0&&(offset%PAGE_SIZE+len+1+circled)>=PAGE_SIZE){//finishing volume
					circled++;
					if(firstwritelength==0)
						firstwritelength=writelength-1;
					else
						firstwritelength--;
				}
				if(firstwritelength>0){//if we had any space on this page, fill it
					status=WRITE_PENDING_DATA1;				
					err=call LogWrite.append(writebuffer, firstwritelength);
				} else {//otherwise we start with the metadata on the next page
					status=WRITE_PENDING_METADATA;				
					err=call LogWrite.append(&current_addr, sizeof(current_addr));
					
				}
			} else {
				firstwritelength=0;
				status=WRITE_PENDING_DATA2;
				err=call LogWrite.append(writebuffer, writelength);
			}
			if(err!=SUCCESS)
				status=NORMAL;
			return err;
		}
	}
	command error_t StreamStorageWrite.appendWithID(nx_uint8_t id, void *buf, uint16_t  len){
		if(status!=NORMAL){
			if(status==UNINIT)
				return EOFF;
			else
				return EBUSY;
		} else if(len>PAGE_SIZE-5){
			return EINVAL;
		}else{
			error_t err;
			uint32_t offset=call LogWrite.currentOffset();
			status=WRITE_PENDING_DATA1;
			writebuffer=buf;
			writelength=len;
			write_id=id;
			if(((offset/PAGE_SIZE)<((offset+len)/PAGE_SIZE))||(offset%PAGE_SIZE)==0||((offset/PAGE_SIZE)%PAGES==0&&(offset%PAGE_SIZE+len+circled)>=PAGE_SIZE)){//data is overlapping to the next page, or we're on the first byte of the page
				firstwritelength=(PAGE_SIZE-(offset%PAGE_SIZE))%PAGE_SIZE;
				if((offset/PAGE_SIZE)%PAGES==0&&(offset%PAGE_SIZE+len+1+circled)>=PAGE_SIZE){//finishing volume
					circled++;
					if(firstwritelength==0)
						firstwritelength=writelength-1;
					else
						firstwritelength--;
				}
				if(firstwritelength>0){//if we had any space on this page, fill it
					status=WRITE_PENDING_ID;
					err=call LogWrite.append(&write_id, sizeof(write_id));			
				} else {//otherwise we start with the metadata on the next page
					status=WRITE_PENDING_METADATA_ID_UNWRITTEN;				
					err=call LogWrite.append(&current_addr, sizeof(current_addr));
					
				}
			} else {
				firstwritelength=0;
				status=WRITE_PENDING_ID;
				err=call LogWrite.append(&write_id, sizeof(write_id));	
			}
			if(err!=SUCCESS)
				status=NORMAL;
			return err;
		}
	}
	
	event void LogWrite.appendDone(void *buf, storage_len_t len, bool recordsLost, error_t error){
		error_t err=SUCCESS;
		if(error!=SUCCESS){
			status=NORMAL;
			if(write_id>0)
				signal StreamStorageWrite.appendDoneWithID(writebuffer, writelength, error);
			else
				signal StreamStorageWrite.appendDone(writebuffer, writelength, error);
			return;
		} 
		if(status!=WRITE_PENDING_METADATA&&status!=WRITE_PENDING_METADATA_ID_UNWRITTEN)
			current_addr+=len;
		if(minAddress.valid&&recordsLost){
			minAddress.valid=FALSE;
		}
		if(addressTranslation.success&&(addressTranslation.logAddress-call LogWrite.currentOffset()>0)&&(addressTranslation.logAddress-call LogWrite.currentOffset()<PAGE_SIZE))
			addressTranslation.success=FALSE;
		switch(status){
			case WRITE_PENDING_DATA1:{//we're done with the first page, now we write the pagestarter metadata
				status=WRITE_PENDING_METADATA;
				err=call LogWrite.append(&current_addr, sizeof(current_addr));
			}break;
			case WRITE_PENDING_METADATA:{//we're done with the metadata, now we write the rest of the data, or the ID	
				status=WRITE_PENDING_DATA2;
				err=call LogWrite.append(writebuffer+firstwritelength, writelength-firstwritelength);
			}break;
			case WRITE_PENDING_METADATA_ID_UNWRITTEN:{//we're done with the metadata, now we write the ID	
				status=WRITE_PENDING_ID;
				err=call LogWrite.append(&write_id, sizeof(write_id));	
			}break;
			case WRITE_PENDING_DATA2:{//we're done with the data, now we write the ID
				status=NORMAL;
				if(write_id==0)
					signal StreamStorageWrite.appendDone(writebuffer, writelength, SUCCESS);
				else
					signal StreamStorageWrite.appendDoneWithID(writebuffer, writelength, SUCCESS);
			}break;
			case WRITE_PENDING_ID:{//we wrote everything
				if(firstwritelength>0){//we don't have enough space for all the data
					firstwritelength--;//we already wrote the id (1 byte)
					if(firstwritelength>0){//and we still have empty space on the page
						status=WRITE_PENDING_DATA1;
						err=call LogWrite.append(writebuffer, firstwritelength);
					} else {
						status=WRITE_PENDING_METADATA;
						err=call LogWrite.append(&current_addr, sizeof(current_addr));
					}
				} else {
					status=WRITE_PENDING_DATA2;
					err=call LogWrite.append(writebuffer, writelength);
				}
				
			}break;
		}
		if(err!=SUCCESS){
			status=NORMAL;
			if(write_id>0)
				signal StreamStorageWrite.appendDoneWithID(writebuffer, writelength, error);
			else
				signal StreamStorageWrite.appendDone(writebuffer, writelength, error);
			return;
		} 
	}	
//Read

	command error_t StreamStorageRead.read(uint32_t addr, void *buf, uint8_t len){
		if(status!=NORMAL)
			if(status==UNINIT)
				return EOFF;
			else
				return EBUSY;
		else {
			error_t err;
			status=READ_PENDING_SEEK;
			readbuffer=buf;
			readlength=len;
			if(addressTranslation.success){
				addressTranslation.success=FALSE;
				addressTranslation.streamAddress-=addressTranslation.logAddress%254-sizeof(current_addr);
				addressTranslation.logAddress-=addressTranslation.logAddress%254;
				#ifdef DEBUG
					printf("%ld,%ld\n",addressTranslation.logAddress,addressTranslation.streamAddress);
					printfflush();
				#endif
				if((addr-addressTranslation.streamAddress<(PAGE_SIZE-sizeof(current_addr)))&&(addr-addressTranslation.streamAddress>=0)){
						#ifdef DEBUG
							printf("Data is on this page\n");
						#endif
						addressTranslation.logAddress=addressTranslation.logAddress+(storage_cookie_t)(addr-addressTranslation.streamAddress+sizeof(current_addr));//jump to the data
						if((addressTranslation.logAddress%PAGE_SIZE)>=((addressTranslation.logAddress+readlength)%PAGE_SIZE)){ //the data was cut half with metadata
							readfirstlength=PAGE_SIZE-(addressTranslation.logAddress%PAGE_SIZE);
							status=READ_PENDING_DATA1;
						} else {
							readfirstlength=0;
							status=READ_PENDING_DATA2;
						}	
					}else{
						#ifdef DEBUG
							printf("%ld-%ld=%ld\n",addr,addressTranslation.streamAddress,addr-addressTranslation.streamAddress);
						#endif
						if((int32_t)(addr-addressTranslation.streamAddress)>0){//forward
							status=READ_PENDING_SEEK_STEP_F;
							//													 	kulombseg		  +				metadata									/PAGE_SIZE egeszresz				
							addressTranslation.logAddress=addressTranslation.logAddress+(storage_cookie_t)((addr-addressTranslation.streamAddress+((addr-addressTranslation.streamAddress)/PAGE_SIZE)*sizeof(current_addr))/PAGE_SIZE)*PAGE_SIZE;
							#ifdef DEBUG
								printf("Forward\n");
							#endif
						}else{//backward	//TODO testing
							status=READ_PENDING_SEEK_STEP_B;
							addressTranslation.logAddress=addressTranslation.logAddress-(storage_cookie_t)((addressTranslation.streamAddress-addr+((addressTranslation.streamAddress-addr)/PAGE_SIZE)*sizeof(current_addr))/PAGE_SIZE+1)*PAGE_SIZE;					
							#ifdef DEBUG
								printf("Backward\n");
							#endif
						}				
					}
					#ifdef DEBUG
						printf("Jump to %ld\n",addressTranslation.logAddress);
						printfflush();
					#endif
					addressTranslation.streamAddress=addr;
					err=call LogRead.seek(addressTranslation.logAddress);
			} else {
				addressTranslation.streamAddress=addr;
				status=READ_PENDING_SEEK;
				
				//we will read the first metadata, to know where should we search
				err=call LogRead.seek(SEEK_BEGINNING);
			}
			if(err!=SUCCESS)
				status=NORMAL;
			return err;
		}	
	}
	

	
	event void LogRead.readDone(void *buf, storage_len_t len, error_t error){
		error_t err=SUCCESS;
		if(error!=SUCCESS){
			switch(status){
				case INIT_STEP:{
					#ifdef DEBUG
							printf("Found end of data, %ld\n",current_addr);
							printfflush();
					#endif	
					status=NORMAL;
					signal SplitControl.startDone(SUCCESS);
					return;
				}break;
				case READ_PENDING_DATA1:
				case READ_PENDING_DATA2:{//maybe because the page was synced. try the next page
					#ifdef DEBUG
							printf("Read error, go to %ld\n",last_page+PAGE_SIZE);
					#endif
					status=READ_PENDING_SEEK_STEP_F;
					err=call LogRead.seek(last_page+PAGE_SIZE);	
				}break;
				case GET_MIN:{
					status=NORMAL;
					signal StreamStorageRead.getMinAddressDone(0, error);
					return;
				}break;
				default:{
					#ifdef DEBUG
							printf("Read error\n");
							printfflush();
					#endif	
                    status=NORMAL;
					signal StreamStorageRead.readDone(readbuffer, readlength, error);
					return;
				}break;
			}
		}else{ 
			switch(status){
				case READ_PENDING_SEEK:{
					nx_uint32_t *metadata=(nx_uint32_t*)buf;//unfortunately, we need this, because the endiannes is unpredictable in the buffer
					if(((call LogRead.currentOffset()-len)%254)!=0){
						#ifdef DEBUG
							printf("SB: %ld, Jump to %ld\n",call LogRead.currentOffset()-len,call LogRead.currentOffset()-len+PAGE_SIZE-(call LogRead.currentOffset()-len)%PAGE_SIZE);
							printfflush();
						#endif
						err=call LogRead.seek(call LogRead.currentOffset()-len+PAGE_SIZE-(call LogRead.currentOffset()-len)%PAGE_SIZE);
					}else {
						addressTranslation.logAddress=call LogRead.currentOffset()-len;
						#ifdef DEBUG
							printf("Metadata at %ld: %ld\n",call LogRead.currentOffset()-len,*metadata);
						#endif
						last_page=call LogRead.currentOffset()-len;
						if((addressTranslation.streamAddress-*metadata<=(PAGE_SIZE-sizeof(current_addr)))&&(addressTranslation.streamAddress-*metadata>=0)){
							#ifdef DEBUG
								printf("Data is on this page\n");
							#endif
							addressTranslation.logAddress+=(storage_cookie_t)(addressTranslation.streamAddress-*metadata+sizeof(current_addr));//jump to the data
							if((addressTranslation.logAddress%PAGE_SIZE)>((addressTranslation.logAddress+readlength)%PAGE_SIZE)){ //the data was cut half with metadata
								readfirstlength=PAGE_SIZE-(addressTranslation.logAddress%PAGE_SIZE);
								status=READ_PENDING_DATA1;
							} else {
								readfirstlength=0;
								status=READ_PENDING_DATA2;
							}	
						}else{
							if((int32_t)(addressTranslation.streamAddress-*metadata>0)){//forward
								status=READ_PENDING_SEEK_STEP_F;
								//													 	kulombseg		  +				metadata									/PAGE_SIZE egeszresz				
								addressTranslation.logAddress=addressTranslation.logAddress+(storage_cookie_t)((addressTranslation.streamAddress-*metadata+((addressTranslation.streamAddress-*metadata)/PAGE_SIZE)*sizeof(current_addr))/PAGE_SIZE)*PAGE_SIZE;
								#ifdef DEBUG
									printf("Forward\n");
								#endif
							}else{//backward	//TODO testing
								status=READ_PENDING_SEEK_STEP_B;
								addressTranslation.logAddress=addressTranslation.logAddress-(storage_cookie_t)((*metadata-addressTranslation.streamAddress+((*metadata-addressTranslation.streamAddress)/PAGE_SIZE)*sizeof(current_addr))/PAGE_SIZE+1)*PAGE_SIZE;					
								#ifdef DEBUG
									printf("Backward\n");
								#endif
							}				
						}
						#ifdef DEBUG
							printf("Jump to %ld\n",addressTranslation.logAddress);
							printfflush();
						#endif
						err=call LogRead.seek(addressTranslation.logAddress);
					}
				}break;
				case READ_PENDING_SEEK_STEP_F:{
					nx_uint32_t *metadata=(nx_uint32_t*)buf;//unfortunately, we need this, because the endiannes is unpredictable in the buffer
					addressTranslation.logAddress=call LogRead.currentOffset()-len;
					last_page=call LogRead.currentOffset()-call LogRead.currentOffset()%PAGE_SIZE;
					#ifdef DEBUG
						printf("Metadata at %ld: %ld\n",call LogRead.currentOffset()-len,*metadata);
						printfflush();
					#endif
					if((addressTranslation.streamAddress-*metadata)>=(PAGE_SIZE-len)){//the data will be somewhere on the next pages
						#ifdef DEBUG
							printf("Next page\n");
							printfflush();
						#endif
						addressTranslation.logAddress+=PAGE_SIZE;
						err=call LogRead.seek(addressTranslation.logAddress);
					} else if(addressTranslation.streamAddress-*metadata<0){//seems like the data is somewhere before us (which should be impossible), or not in the flash (overwritten?)
						status=NORMAL;
                        signal StreamStorageRead.readDone(readbuffer, readlength, FAIL);
                    }
					else{//the data is on this page
						#ifdef DEBUG
							printf("Data is on this page\n");
							printfflush();
						#endif
						addressTranslation.logAddress+=(storage_cookie_t)(addressTranslation.streamAddress-*metadata+len);//jump to the data
						if((addressTranslation.logAddress%PAGE_SIZE)>((addressTranslation.logAddress+readlength)%PAGE_SIZE)){ //the data was cut half with metadata
							readfirstlength=PAGE_SIZE-(addressTranslation.logAddress%PAGE_SIZE);
							status=READ_PENDING_DATA1;
						} else {
							readfirstlength=0;
							status=READ_PENDING_DATA2;
						}
						#ifdef DEBUG
							printf("Jump to %ld\n",addressTranslation.logAddress);
							printfflush();
						#endif
						err=call LogRead.seek(addressTranslation.logAddress);
					}
											
				}break;
				case READ_PENDING_SEEK_STEP_B:{
					nx_uint32_t *metadata=(nx_uint32_t*)buf;//unfortunately, we need this, because the endiannes is unpredictable in the buffer
					addressTranslation.logAddress=call LogRead.currentOffset()-len;
					last_page=call LogRead.currentOffset()-call LogRead.currentOffset()%PAGE_SIZE;
					#ifdef DEBUG
						printf("Metadata at %ld: %ld\n",call LogRead.currentOffset()-len,*metadata);
					#endif
					if(addressTranslation.streamAddress-*metadata<0){//the data will be somewhere on the previous pages
						#ifdef DEBUG
							printf("Prev page\n");
							printfflush();
						#endif
						addressTranslation.logAddress-=PAGE_SIZE;
						err=call LogRead.seek(addressTranslation.logAddress);
					} else if(addressTranslation.streamAddress-*metadata>=PAGE_SIZE+len){//seems like the data is somewhere ahead us (which should be impossible), or not in the flash (overwritten?) 
						status=NORMAL;
                        signal StreamStorageRead.readDone(readbuffer, readlength, FAIL);
                    }else{//the data is on this page
						#ifdef DEBUG
							printf("Data is on this page\n");
							printfflush();
						#endif
						addressTranslation.logAddress+=(storage_cookie_t)(addressTranslation.streamAddress-*metadata+len);//jump to the data
						if((addressTranslation.logAddress%PAGE_SIZE)>((addressTranslation.logAddress+readlength)%PAGE_SIZE)){ //the data was cut half with metadata
							readfirstlength=PAGE_SIZE-(addressTranslation.logAddress%PAGE_SIZE);
							status=READ_PENDING_DATA1;
						} else {
							readfirstlength=0;
							status=READ_PENDING_DATA2;
						}
						#ifdef DEBUG
							printf("Jump to %ld\n",addressTranslation.logAddress);
							printfflush();
						#endif
						err=call LogRead.seek(addressTranslation.logAddress);
					}
											
				}break;
				case READ_PENDING_DATA1:{//we read the first half of the data, now we jump over the metadata
					if(addressTranslation.logAddress+len==call LogRead.currentOffset()){
						status=READ_PENDING_DATA2;
						err=call LogRead.seek(call LogRead.currentOffset()+sizeof(current_addr));	
					} else {//we read something from the next page (incl. metadata), so we're correcting this (this could only happen on a synced page)
						uint32_t offset=call LogRead.currentOffset();
						status=READ_PENDING_DATA3;
						readfirstlength=readfirstlength-offset%PAGE_SIZE;
						err=call LogRead.seek(offset-offset%PAGE_SIZE+sizeof(current_addr));
					}
				}break;
				case READ_PENDING_DATA2:{//we're done
					if(addressTranslation.logAddress+((readfirstlength>0)?readfirstlength+sizeof(current_addr):0)+len==call LogRead.currentOffset()){
						addressTranslation.success=TRUE;
						status=NORMAL;
						signal StreamStorageRead.readDone(readbuffer, readlength, SUCCESS);
					} else {//we read something from the next page (incl. metadata), so we're correcting this (this could only happen on a synced page)
						uint32_t offset=call LogRead.currentOffset();
						status=READ_PENDING_DATA3;
						readfirstlength=readlength-offset%PAGE_SIZE;
						err=call LogRead.seek(offset-offset%PAGE_SIZE+sizeof(current_addr));
						//call LogRead.seek(offset-4);
					}
				}break;
				case READ_PENDING_DATA3:{//we're done
					addressTranslation.success=TRUE;
					status=NORMAL;
					signal StreamStorageRead.readDone(readbuffer, readlength, SUCCESS);
				}
				case INIT_START:{
					nx_uint32_t *metadata=(nx_uint32_t*)buf;//unfortunately, we need this, because the endiannes is unpredictable in the buffer
					if(((call LogRead.currentOffset()-len)%254)!=0){
						#ifdef DEBUG
							printf("SB: %ld, Jump to %ld\n",call LogRead.currentOffset()-len,call LogRead.currentOffset()-len+PAGE_SIZE-(call LogRead.currentOffset()-len)%PAGE_SIZE);
							printfflush();
						#endif
						err=call LogRead.seek(call LogRead.currentOffset()-len+PAGE_SIZE-(call LogRead.currentOffset()-len)%PAGE_SIZE);
					} else {
						current_addr=*metadata;
						minAddress.address=*metadata;
						minAddress.valid=TRUE;
						last_page=call LogRead.currentOffset()-len;
						#ifdef DEBUG
							printf("CA: %ld; B: %ld, lp: %ld\n",call LogRead.currentOffset()-sizeof(buffer),*metadata,last_page);
							printfflush();
						#endif	
						status=INIT;
						err=call LogRead.seek(last_page+PAGE_SIZE);	
					}			
				}break;
				case INIT:{//we read all of the metadata, searching for the last page
					nx_uint32_t *metadata=(nx_uint32_t*)buf;//unfortunately, we need this, because the endiannes is unpredictable in the buffer
					#ifdef DEBUG
						printf("CA: %ld; B: %ld\n",call LogRead.currentOffset()-sizeof(buffer),*metadata);
						printfflush();
					#endif
					//Strange behavior: if I change the two sides of the AND relation, it will change the result					
					if((current_addr!=*metadata)&&(((uint32_t)(*metadata-current_addr))<=PAGE_SIZE)){//than it's a correct page. we should check the next one
						last_page=call LogRead.currentOffset()-len;
						current_addr=*metadata;
						err=call LogRead.seek(last_page+PAGE_SIZE);	
					} else {
						#ifdef DEBUG
							printf("Unexpected metadata (%ld vs %ld) seek to %ld\n",current_addr,*metadata,last_page);
							printfflush();
						#endif
						status=INIT_STEP;
						err=call LogRead.seek(last_page);
					}
				}break;
				case INIT_STEP:{
					if((last_page+1==(call LogRead.currentOffset()))&&((call LogRead.currentOffset()%PAGE_SIZE)!=0)){//the address increased by one (and didn't jump to the next page), and it's not the end of the page
						last_page++;
						current_addr++;
//						#ifdef DEBUG
//									printf("Found valid data at %ld\n",call LogRead.currentOffset());
//									printfflush();
//						#endif	
						err=call LogRead.read(&buffer,1);
					} else{
						if(call LogRead.currentOffset()%PAGE_SIZE!=0)
							current_addr--; //the last byte of a synced page was alway false. TODO NEED FURTHER TESTING!
						
						
						if(current_addr<2){//the flash is empty
							#ifdef DEBUG
								printf("The flash is empty\n");
								printfflush();
							#endif		
							current_addr=0;			
						} else{
							current_addr-=4;
							
						}
						#ifdef DEBUG
								printf("Found end of data at %ld:%ld (last:%ld)\n",call LogRead.currentOffset(), current_addr,last_page);
								printfflush();
						#endif
						status=NORMAL;
						signal SplitControl.startDone(SUCCESS);	
					}
				}break;
				case GET_MIN:{
					nx_uint32_t *metadata=(nx_uint32_t*)buf;//unfortunately, we need this, because the endiannes is unpredictable in the buffer
					if(((call LogRead.currentOffset()-len)%254)!=0){
						#ifdef DEBUG
							printf("SB: %ld, Jump to %ld\n",call LogRead.currentOffset()-len,call LogRead.currentOffset()-len+PAGE_SIZE-(call LogRead.currentOffset()-len)%PAGE_SIZE);
							printfflush();
						#endif
						err=call LogRead.seek(call LogRead.currentOffset()-len+PAGE_SIZE-(call LogRead.currentOffset()-len)%PAGE_SIZE);
					}	 else {	
						#ifdef DEBUG
							printf("Minaddr: %ld\n",minAddress.address);
							printfflush();
						#endif		
						minAddress.address=*metadata;
						minAddress.valid=TRUE;
						status=NORMAL;
						signal StreamStorageRead.getMinAddressDone(minAddress.address, SUCCESS);
					}
				}break;
			}
		}
		if(err!=SUCCESS){
			status=NORMAL;
			switch(status){
				case INIT_STEP:{
					signal SplitControl.startDone(err);
				}break;
				case GET_MIN:{
					signal StreamStorageRead.getMinAddressDone(0, err);
				}break;
				default:{
					signal StreamStorageRead.readDone(readbuffer, readlength, err);
				}break;
			}
		}		
		
	}

	event void LogRead.seekDone(error_t error){
		error_t err=SUCCESS;
		if(error!=SUCCESS){
			switch(status){
				case INIT_START:{
					#ifdef DEBUG
						printf("seek to beginning failed\n");
						printfflush();
					#endif	
					status=UNINIT;
					signal SplitControl.startDone(FAIL);
				}break;
				case INIT:{				//probably becouse it's unwritten
					#ifdef DEBUG
						printf("seek error (%d), seek to %ld\n",error,last_page);
					#endif
					status=INIT_STEP;
					err=call LogRead.seek(last_page);
				}break;
				case GET_MIN:{
					status=NORMAL;
					signal StreamStorageRead.getMinAddressDone(0, err);
					return;
				}break;
				case INIT_STEP:{
					#ifdef DEBUG
							printf("Found end of data, %ld\n",current_addr);
							printfflush();
					#endif
					status=NORMAL;
					signal SplitControl.startDone(SUCCESS);	
					return;
				}break;
				default:{
					status=NORMAL;
					signal StreamStorageRead.readDone(readbuffer, readlength, error);
					return;
				}
			}	
		} else {
			switch(status){
				case READ_PENDING_DATA2:
				case READ_PENDING_DATA3:{
					err=call LogRead.read(readbuffer+readfirstlength, readlength-readfirstlength);
				}break;
				case READ_PENDING_DATA1:{
					err=call LogRead.read(readbuffer, readfirstlength);
				}break;
				case INIT_STEP:{
					last_page=call LogRead.currentOffset();//reusing variable
					err=call LogRead.read(&buffer,1);
				}break;
				default:{
					err=call LogRead.read(&buffer, sizeof(buffer));
				}break;
			}				
		}
		if(err!=SUCCESS){
			status=NORMAL;
			switch(status){
				case INIT_STEP:{
					signal SplitControl.startDone(err);
				}break;
				case GET_MIN:{
					signal StreamStorageRead.getMinAddressDone(0, err);
				}break;
				default:{
					signal StreamStorageRead.readDone(readbuffer, readlength, err);
				}break;
			}
		} 
	}

	command uint32_t StreamStorageRead.getMaxAddress(){
        if(current_addr==0)
          return 0;
        else
          return current_addr-1;
	}
	
	task void getMinAddr(){
		signal StreamStorageRead.getMinAddressDone(minAddress.address,SUCCESS);
	}

	command error_t StreamStorageRead.getMinAddress(){
		if(status==UNINIT)
		      return EOFF;
		#ifdef DEBUG
			printf("minaddr");
		#endif
		if(minAddress.valid){
			#ifdef DEBUG
				printf(" valid %ld\n",minAddress.address);
				printfflush();
			#endif
			//signal StreamStorageRead.getMinAddressDone(minAddress.address,SUCCESS);
			post getMinAddr();
			return SUCCESS;
		}else {
			if(status!=NORMAL){
				#ifdef DEBUG
					printf(" busy\n");
					printfflush();
				#endif
				return EBUSY;
			}else{
				error_t err;
				status=GET_MIN;
				err=call LogRead.seek(SEEK_BEGINNING);
				if(err!=SUCCESS)
					status=NORMAL;
				return err;
				#ifdef DEBUG
					printf(" started %ld\n",minAddress.address);
					printfflush();
				#endif
			}
		}
	}
	

	event void LogWrite.syncDone(error_t error){
		status=NORMAL;
		signal StreamStorageWrite.syncDone(error);	
	}

	command error_t StreamStorageWrite.sync(){
		if(status!=NORMAL)
			if(status==UNINIT)
				return EOFF;
			else
				return EBUSY;
		else {
			error_t err;
			status=SYNC_PENDING;
			err=call LogWrite.sync();
			if(err!=SUCCESS)
				status=NORMAL;
			return err;
		}
	}
	
	
	default event void StreamStorageRead.getMinAddressDone(uint32_t addr,error_t error){}
	default event void StreamStorageRead.readDone(void* buf, uint8_t  len, error_t error){}
	default event void StreamStorageErase.eraseDone(error_t error){}
	default event void StreamStorageWrite.appendDoneWithID(void* buf, uint16_t  len, error_t error){}
	default event void StreamStorageWrite.appendDone(void* buf, uint16_t  len, error_t error){}
	default event void StreamStorageWrite.syncDone(error_t error){}
}
