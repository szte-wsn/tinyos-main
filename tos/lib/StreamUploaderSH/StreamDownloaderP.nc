module StreamDownloaderP{
	provides interface SplitControl;
	provides interface Notify<uint32_t> as DownloadDone;
	provides interface StreamDownloaderInfo;
	uses interface SplitControl as RadioControl;
	uses interface Receive;
	uses interface AMSend;
	uses interface AMPacket;
	uses interface Packet;
	
	uses interface Receive as TimeSyncReceive;
	uses interface TimeSyncPacket<TMilli, uint32_t>;
	uses interface Resource;
	uses interface StreamStorageWrite;
	uses interface StreamStorageErase;
	
	uses interface Timer<TMilli> as ResourceTimer;
	uses interface LocalTime<TMilli>;
	uses interface DiagMsg;
}
implementation{
	#ifndef DOWNLOADING_FROM
	#define DOWNLOADING_FROM 0xffff
	#endif
	
	uint16_t downloading_from=DOWNLOADING_FROM;
	uint32_t timestamps[4]; bool timestamp_empty=TRUE; //0:firstlocal, 1:firstremote, 2: lastlocal, 3: lastremote
	uint32_t startAddress=0, endAddress=0;
	message_t request;
	bool init=TRUE;
	bool start=TRUE;
	bool notifyEnabled=TRUE;
	
	enum{
		RESOURCE_TIME=20000,
		RESOURCE_TIME_NOMOTE=120000,
	};
	
	command uint16_t StreamDownloaderInfo.getNodeId(){
		return downloading_from;
	}
	
	command uint32_t StreamDownloaderInfo.getOffset(){
		return (uint32_t)(timestamps[0]-timestamps[1]);
	}
	
	command uint32_t StreamDownloaderInfo.getSkew(){
		uint64_t temp = (uint64_t)(timestamps[3]-timestamps[1])*100;
		return (uint32_t)((temp)/(uint32_t)(timestamps[2]-timestamps[0]));
	}
	
	command uint32_t StreamDownloaderInfo.convertTimeStamp(uint32_t other, bool localToRemote){
		if(!localToRemote){
			uint64_t temp = ((uint64_t)other * call StreamDownloaderInfo.getSkew()) / 100;
			temp += call StreamDownloaderInfo.getOffset();
			return (uint32_t)(temp);
		} else {
			uint64_t temp = ((uint64_t)other * 100) / call StreamDownloaderInfo.getSkew();
			temp -= call StreamDownloaderInfo.getOffset();
			return (uint32_t)(temp);
		}
	}
	
	command uint32_t StreamDownloaderInfo.convertTimeStampToRelativeTime(uint32_t remotetime){
		return (uint32_t)(call LocalTime.get() - call StreamDownloaderInfo.convertTimeStamp(remotetime, FALSE));
	}
	
	command error_t DownloadDone.enable(){
		notifyEnabled = TRUE;
		return SUCCESS;
	}
	
	command error_t DownloadDone.disable(){
		notifyEnabled = FALSE;
		return SUCCESS;
	}
	
	command error_t SplitControl.start(){
		if( call DiagMsg.record() ){
			call DiagMsg.str("ST");
			call DiagMsg.send();
		}
		start = TRUE;
		return call Resource.request();
	}
	
	command error_t SplitControl.stop(){
		return call RadioControl.stop();
	}
	
	event void RadioControl.stopDone(error_t err){
		call Resource.release();
		signal SplitControl.stopDone(err);
	}
	
	event void StreamStorageErase.eraseDone(error_t err){
		if( call DiagMsg.record() ){
			call DiagMsg.str("E");
			call DiagMsg.uint8(err);
			call DiagMsg.send();
		}
		call ResourceTimer.startOneShot(RESOURCE_TIME_NOMOTE);
		init = FALSE;
		start = FALSE;
		if( err == SUCCESS )
			err = call RadioControl.start();
		if( err != SUCCESS )
			signal SplitControl.startDone(err);
	}
	
	event void RadioControl.startDone(error_t err){
		if( call DiagMsg.record() ){
			call DiagMsg.str("R");
			call DiagMsg.uint8(err);
			call DiagMsg.send();
		}
		signal SplitControl.startDone(err);
	}
	
	event message_t* TimeSyncReceive.receive(message_t *msg, void *payload, uint8_t len){
		if( call DiagMsg.record() ){
			call DiagMsg.str("rec");
			call DiagMsg.uint16(downloading_from);
			call DiagMsg.uint16(call AMPacket.source(msg));
			call DiagMsg.send();
		}
		if( downloading_from == 0xffff ){
			downloading_from = call AMPacket.source(msg);
		}
		if( call AMPacket.source(msg) == downloading_from ){
			ctrl_msg* control = (ctrl_msg*)payload;
			ctrl_msg *req = call Packet.getPayload(&request, sizeof(ctrl_msg));
			if( call TimeSyncPacket.isValid(msg) ){
				if(timestamp_empty){
					if( call DiagMsg.record() ){
						call DiagMsg.str("TS1");
						call DiagMsg.uint32(call TimeSyncPacket.eventTime(msg));
						call DiagMsg.uint32(control -> localtime);
						call DiagMsg.send();
					}
					timestamp_empty = FALSE;
					timestamps[0] = call TimeSyncPacket.eventTime(msg);
					timestamps[1] = control -> localtime;
				} else {
					if( call DiagMsg.record() ){
						call DiagMsg.str("TSE");
						call DiagMsg.uint32(call TimeSyncPacket.eventTime(msg));
						call DiagMsg.uint32(control -> localtime);
						call DiagMsg.send();
					}
					timestamps[2] = call TimeSyncPacket.eventTime(msg);
					timestamps[3] = control -> localtime;
				}
			}
			if( endAddress == control->max_address ) //nothing to download
				return msg;
			if( startAddress == endAddress || endAddress < control->min_address ){
					startAddress = endAddress = req->min_address;
					req->min_address = control->min_address;
			} else {
				req->min_address = endAddress + 1;
			}
			if( req->min_address + MESSAGE_SIZE - 1 > control->max_address ){
				req->min_address = control->max_address - MESSAGE_SIZE + 1;       
			}
			req->max_address = req->min_address + MESSAGE_SIZE - 1;
			if( call DiagMsg.record() ){
				call DiagMsg.str("rec2");
				call DiagMsg.uint16(downloading_from);
				call DiagMsg.uint32(startAddress);
				call DiagMsg.uint32(endAddress);
				call DiagMsg.send();
			}
			if( call DiagMsg.record() ){
				call DiagMsg.str("rec2");
				call DiagMsg.uint32(control->min_address);
				call DiagMsg.uint32(control->max_address);
				call DiagMsg.uint32(req->min_address);
				call DiagMsg.uint32(req->max_address);
				call DiagMsg.send();
			}
			if( req->min_address < req->max_address && endAddress < req->max_address ){ //there's a minimal chance of overflow
				if( call Resource.isOwner() || call Resource.request() == SUCCESS ){
					call ResourceTimer.startOneShot(RESOURCE_TIME);
					call AMSend.send(downloading_from, &request, sizeof(ctrl_msg));
				} else
					call Resource.request();
			}
		}
		return msg;
	}
	
	event void Resource.granted(){
// 		if( call DiagMsg.record() ){
// 			call DiagMsg.str("gr");
// 			call DiagMsg.send();
// 		}
		if(init){
			call StreamStorageErase.erase();
		} else {
			if(start){
				call ResourceTimer.startOneShot(RESOURCE_TIME_NOMOTE);
				call RadioControl.start();
				start = FALSE;
			}else {
				call ResourceTimer.startOneShot(RESOURCE_TIME);
			}
			call AMSend.send(downloading_from, &request, sizeof(ctrl_msg));
		}
	}
	
	event void AMSend.sendDone(message_t *msg, error_t error){
		
	}
	
	event message_t* Receive.receive(message_t *msg, void *payload, uint8_t len){
		data_msg *data = (data_msg*)payload;
		if( call DiagMsg.record() ){
			call DiagMsg.str("data");
			call DiagMsg.uint16(downloading_from);
			call DiagMsg.uint32(startAddress);
			call DiagMsg.uint32(endAddress);
			call DiagMsg.uint32(data->address);
			call DiagMsg.send();
		}
// 		if( call DiagMsg.record() ){;
// 			call DiagMsg.uint32(data->address);
// 			call DiagMsg.hex8s((uint8_t*)(data->data), 8);
// 			call DiagMsg.hex8s((uint8_t*)(data->data+8), 8);
// 			call DiagMsg.hex8s((uint8_t*)(data->data+16), 8);
// 			call DiagMsg.send();
// 		}
		if( data->address == endAddress + 1 || startAddress == endAddress ){
			call StreamStorageWrite.append(data->data, MESSAGE_SIZE);
		} else if( data->address <= endAddress && data->address + MESSAGE_SIZE - 1 > endAddress ) {
			if( call DiagMsg.record() ){
				call DiagMsg.str("end");
				call DiagMsg.uint16(downloading_from);
				call DiagMsg.uint32(endAddress - data->address + 1);
				call DiagMsg.uint32(data->address+MESSAGE_SIZE-endAddress-1);
				call DiagMsg.send();
			}
			call StreamStorageWrite.append( (uint8_t*)((data->data ) + ( endAddress - (data->address) + 1)) , data->address+MESSAGE_SIZE-endAddress-1);
		}
		return msg;
	}
	
	event void StreamStorageWrite.appendDone(void* buf, uint16_t  len, error_t error){
		if(error == SUCCESS){
			if( startAddress == endAddress )
				endAddress--;//0 address
			endAddress += len;
		}
		if( call DiagMsg.record() ){
			call DiagMsg.str("dataD");
			call DiagMsg.uint8(error);
			call DiagMsg.uint16(len);
			call DiagMsg.uint32(startAddress);
			call DiagMsg.uint32(endAddress);
			call DiagMsg.send();
		}
	}
	
	event void ResourceTimer.fired(){
		call Resource.release();
		if( notifyEnabled)
			signal DownloadDone.notify(endAddress);
	}
	
	event void StreamStorageWrite.appendDoneWithID(void* buf, uint16_t  len, error_t error){}
	event void StreamStorageWrite.syncDone(error_t error){}
	
	default event void SplitControl.startDone(error_t err){}
	default event void DownloadDone.notify(uint32_t endAddr){}
}