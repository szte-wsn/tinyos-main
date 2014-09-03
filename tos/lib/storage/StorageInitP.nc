#include "PageStorage.h"
#include "TranslationLookasideBuffer.h"
#include "PageMetaLayer.h"
generic module StorageInitP(){
	uses interface PageMeta;
	uses interface TranslationLookasideBuffer as TLB;
	provides interface SplitControl;
	
	uses interface Set<uint32_t> as PageAllocatorInit;
	uses interface Set<uint32_t> as MetaInit;
	uses interface AddressTranslatorInit;
	uses interface DiagMsg;
}
implementation{
	
	enum{
		S_OFF,
		S_FIRSTPAGE,
		S_SEARCH,
		S_SEARCH_FULL,
		S_SEARCH_DONE,
		S_ON,
	};
	
	uint8_t state = S_OFF;
	
	typedef struct page_info_t{
		uint32_t page;
		metadata_t meta;
	}page_info_t;
	
	page_info_t pageA, pageB;
	uint32_t searchLength;
	bool readToPageA;
	
	inline bool isEmpty(void* data){
		uint8_t i;
		for(i=0;i<sizeof(metadata_t);i++){
			if( *(uint8_t*)(data+i) != EMPTY_BYTE ){
				return FALSE;
			}
		}
		return TRUE;
	}
	
	
	command error_t SplitControl.start(){
		state = S_FIRSTPAGE;
		readToPageA = TRUE;
		if(call DiagMsg.record()){
			call DiagMsg.str("init start");
			call DiagMsg.send();
		}
		return call PageMeta.readMeta(0);
	}
	
	task void stopDone(){
		signal SplitControl.stopDone(SUCCESS);
	}
	
	command error_t SplitControl.stop(){
		post stopDone();
		return SUCCESS;
	}
	
	
	//Az a baj, hogy ez a függvény az eventből fut, ezért a TranslatorInit után a translator is megkapja az eventet
	inline void initDone(uint32_t lastStartAddress, uint16_t lastFilledBytes, uint32_t lastPage, uint32_t minPage, bool empty, bool fail){
		if(!fail){
			if( !empty ){
				call PageAllocatorInit.set(lastPage);
				call MetaInit.set(lastStartAddress + lastFilledBytes);
				call AddressTranslatorInit.init(minPage, lastPage, lastStartAddress, lastFilledBytes);
			} else {
				call PageAllocatorInit.set(call PageMeta.getNumPages() - 1);
				call MetaInit.set(0);
				call AddressTranslatorInit.init(0, 0, 0, 0);
			}
			state = S_ON;
			signal SplitControl.startDone(SUCCESS);
		} else {
			signal SplitControl.startDone(FAIL);
		}
		if(call DiagMsg.record()){
			call DiagMsg.str("i dn");
			call DiagMsg.uint8(empty);
			call DiagMsg.uint32(lastStartAddress);
			call DiagMsg.uint32(lastFilledBytes);
			call DiagMsg.uint32(lastPage);
			call DiagMsg.uint32(minPage);
			call DiagMsg.send();
		}
	}
	
	event void PageMeta.readMetaDone(uint32_t pageNum, void *buffer, error_t error){
		if(state != S_ON){
			if( error == SUCCESS ){
				metadata_t* meta = (metadata_t*)buffer;
				if(call DiagMsg.record()){
					call DiagMsg.str("init rdone");
					call DiagMsg.uint32(pageNum);
					call DiagMsg.uint32(meta->startAddress);
					call DiagMsg.uint32(meta->filledBytes);
					call DiagMsg.uint8(readToPageA);
					call DiagMsg.send();
				}
				
				if(readToPageA){
					pageA.meta = *meta;
					pageA.page = pageNum;
					readToPageA = FALSE;
				} else {
					pageB.meta = *meta;
					pageB.page = pageNum;
				}
				call PageMeta.releaseReadBuffer();
				if(!isEmpty(meta))
					call TLB.addNew(meta->startAddress, pageNum, meta->filledBytes);
				else
					call PageMeta.invalidate(pageNum, pageNum);
				
				if(state == S_FIRSTPAGE){
					if(pageNum == 0 ){
						call PageMeta.readMeta(call PageMeta.getNumPages() -1 );
					} else {
						if( isEmpty(&pageB.meta) ){
							if(call DiagMsg.record()){
								call DiagMsg.str("emptB");
								call DiagMsg.send();
							}
							if( isEmpty(&pageA.meta) ){//both page empty, flash is empty
								if(call DiagMsg.record()){
									call DiagMsg.str("emptA");
									call DiagMsg.send();
								}
								initDone(0, 0, 0, 0, TRUE, FALSE);
							} else { //last page is empty, not full flash
								searchLength = pageB.page - pageA.page;
								state = S_SEARCH;
							}
						} else {
							if( isEmpty(&pageA.meta) ){ //first page is empty (bacause it's erased), so the first data should be in the first page of the second sector
								initDone(pageB.meta.startAddress, pageB.meta.filledBytes, pageB.page, pageA.page + (call PageMeta.getSectorSize() / call PageMeta.getPageSize()), FALSE, FALSE);
							} else if(pageB.meta.startAddress > pageA.meta.startAddress){//flash is full, but no data is overwritten (yet)
								initDone(pageB.meta.startAddress, pageB.meta.filledBytes, pageB.page, pageA.page, FALSE, FALSE);
							} else { //flash is full, some data is overwritten, some data might be erased for write
								searchLength = pageB.page - pageA.page;
								state = S_SEARCH;
							}
						}
					}
				} 
				if( state == S_SEARCH ){
					if(searchLength > 1){
						uint32_t readPage = pageB.page;
						searchLength >>= 1;
						if( isEmpty(&pageB.meta) || pageB.meta.startAddress < pageA.meta.startAddress ){ //if the flash is not full, the second condition will never be true
							readPage -= searchLength;
						} else {
							readPage += searchLength;
							call PageMeta.readMeta(pageB.page + searchLength);
						}
						if( readPage >= call PageMeta.getNumPages() ){
							initDone(0, 0, 0, 0, TRUE, TRUE);
						} else {
							call PageMeta.readMeta(readPage);
						}
					} else if( isEmpty(&pageB.meta) || pageB.meta.startAddress < pageA.meta.startAddress ){ //we're done, but pageB is empty
						call PageMeta.readMeta(pageB.page - 1);//this should be the last written page
					} else {
						uint32_t minPage;
						if( pageA.meta.startAddress == 0 )
							minPage = pageA.page;
						else
							minPage = ( (pageB.page/(call PageMeta.getSectorSize() / call PageMeta.getPageSize()) + 1) * (call PageMeta.getSectorSize() / call PageMeta.getPageSize()));//first page on the next sector
						initDone(pageB.meta.startAddress, pageB.meta.filledBytes, pageB.page, minPage, FALSE, FALSE);
					}
				}
			}
		}
	}
	
	event void PageMeta.readPageDone(uint32_t pageNum, void *buffer, uint32_t startAddress, uint16_t filledBytes, error_t error){}
	
	event void PageMeta.flushWriteBufferDone(uint32_t pageNum, uint32_t startAddress, uint16_t filledBytes, uint32_t lostBytes, error_t error){}
	
	event void PageMeta.eraseDone(bool realErase, error_t error){}
	
	default event void SplitControl.startDone(error_t err){}
	default event void SplitControl.stopDone(error_t err){}
}