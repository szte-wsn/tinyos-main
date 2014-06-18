#include "PageStorage.h"
module TestStorageP{
	provides interface TestStorage;
	uses interface PageLayer;
	uses interface Random;
	#ifdef TESTSTORAGE_PRINT_BUFFER_ON_FAIL
	uses interface DiagMsg;
	#endif
}
implementation{
	error_t lastError;
	uint8_t writeBuffer[PAGE_SIZE];
	uint8_t readBuffer[PAGE_SIZE];
	uint16_t bufferError = 0;
	
	task void eraseDone(){
		signal TestStorage.eraseDone(lastError);
	}
	
	task void writeDone(){
		signal TestStorage.writeDone(lastError);
	}
	
	task void readDone(){
		signal TestStorage.readDone(lastError, bufferError);
	}
	
	command void TestStorage.eraseTest(uint32_t testPage){
		testPage /= (call PageLayer.getNumPages() / call PageLayer.getNumSectors());
		lastError = call PageLayer.erase(testPage, TRUE);
		if( lastError != SUCCESS ){
			post eraseDone();
		}
	}
	
	event void PageLayer.eraseDone(uint32_t sectorNum, bool realErase, error_t error){
		signal TestStorage.eraseDone(error);
	}
	
	command void TestStorage.writeTest(uint32_t testPage){
		uint16_t i;
		for(i=0;i<PAGE_SIZE;i++){
			writeBuffer[i] = (uint8_t)(call Random.rand16()%256);
		}
		lastError = call PageLayer.write(testPage, writeBuffer);
		if( lastError != SUCCESS ){
			post writeDone();
		}
	}
	
	event void PageLayer.writeDone(uint32_t pageNum, void *buffer, error_t error){
		signal TestStorage.writeDone(error);
	}
	
	command void TestStorage.readTest(uint32_t testPage){
		bufferError = 0;
		lastError = call PageLayer.read(testPage, readBuffer);
		if( lastError != SUCCESS ){
			post readDone();
		}
	}
	
	event void PageLayer.readDone(uint32_t pageNum, void *buffer, error_t error){
		uint16_t i;
		#ifdef TESTSTORAGE_PRINT_BUFFER_ON_FAIL
		int16_t firstError=-1;
		#endif
		if( error == SUCCESS ){
			bufferError = 0;
			for(i=0;i<PAGE_SIZE;i++){
				if( readBuffer[i] != writeBuffer[i] ){
					bufferError ++;
					#ifdef TESTSTORAGE_PRINT_BUFFER_ON_FAIL
					if( firstError == -1){
						firstError = i;
					}
					#endif
				}
			}
		}
		#ifdef TESTSTORAGE_PRINT_BUFFER_ON_FAIL
		if(bufferError>0){
			if(call DiagMsg.record()){
				call DiagMsg.uint16(bufferError);
				call DiagMsg.hex8(firstError);
				call DiagMsg.send();
			}
			for(i=0;i<PAGE_SIZE;i+=16){
				if(call DiagMsg.record()){
					call DiagMsg.hex8(i);
					call DiagMsg.hex8s((uint8_t*)(readBuffer+i),8);
					call DiagMsg.hex8s((uint8_t*)(readBuffer+i+8),8);
					call DiagMsg.send();
				}
				if(call DiagMsg.record()){
					call DiagMsg.hex8(i);
					call DiagMsg.hex8s((uint8_t*)(writeBuffer+i),8);
					call DiagMsg.hex8s((uint8_t*)(writeBuffer+i+8),8);
					call DiagMsg.send();
				}
			}
		}
		#endif
		
		signal TestStorage.readDone(error, bufferError);
	}
	
	command uint16_t TestStorage.getPageSize(){
		return call PageLayer.getPageSize();
	}
	
	command uint32_t TestStorage.getNumPages(){
		return call PageLayer.getNumPages();
	}
	
	command uint32_t TestStorage.getRandomPage(){
		return (call Random.rand32() % call PageLayer.getNumPages());
	}
	
	default event void TestStorage.eraseDone(error_t err){}
	default event void TestStorage.writeDone(error_t err){}
	default event void TestStorage.readDone(error_t err, uint16_t buffError){}
}