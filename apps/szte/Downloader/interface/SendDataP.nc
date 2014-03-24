#include "SendData.h"

module SendDataP {
	uses{
		interface Timer<TMilli> as Timer_mes;
		interface Leds;
		interface Boot;
		interface SplitControl;
		interface Receive as radRecGetSliceMsg; 
		interface Receive as radRecCommandMsg; 
		interface Receive as radRecFreeMsg;
		interface AMSend;

		interface Storage;
	}
}
implementation {

	uint8_t buffer[MEASUREMENT_LENGTH];
	
	uint8_t mes_id;
	uint16_t c;		//teszteleshez
	message_t pkt;

	bool sending = FALSE;


	task void mesCreate() {
		int i = 0;
		int szamol = 1;
		for(i = 0; i < MEASUREMENT_LENGTH; i++) {
			buffer[i] = szamol;
			szamol = szamol + 1;
		}
		call Timer_mes.startOneShot(TIMER_PERIOD_MILLI);	//adatmentes
	}

	event void Boot.booted() {
		call SplitControl.start();		
	}
	

	event void SplitControl.startDone(error_t error) {
		post mesCreate();	
	}

	event void SplitControl.stopDone(error_t error) {
	}

	event void Timer_mes.fired() {
		if(call Storage.store(buffer)==SUCCESS) {	//amig nincs tele addig rakjuk a bufferbe az adatokat
			c = c + 1;
		} 
		post mesCreate();		//ujabb adatot generalunk
	}

	event void Storage.takeDone() {		//ha minden adatot a bufferbol kikuldtunk
	}

	event void Storage.deleteDone() {	//minden adatot torolni a bufferbol
		c = 0;
		if(TRUE == sending) {
			if(call Storage.take() == SUCCESS) {}		//folytatom a meresek kikuldeset
		} else {
			if(call Storage.commEnd() == SUCCESS) {
			}
		}
	}

	event message_t* radRecGetSliceMsg.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(GetSliceMsg)) {
			GetSliceMsg* btrpkt = (GetSliceMsg*) (call AMSend.getPayload(msg, sizeof(GetSliceMsg)));
			if(TOS_NODE_ID == btrpkt -> node_id) {
				if(call Storage.getSlice(btrpkt -> mes_id, btrpkt -> slice) == SUCCESS) {
				} 
			}
		}
		return msg;
	}

	event message_t* radRecCommandMsg.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(CommandMsg)) {		
			CommandMsg* btrpkt = (CommandMsg*) (call AMSend.getPayload(msg, sizeof(CommandMsg)));
			if(btrpkt -> node_id_start == TOS_NODE_ID) {	//elkezd adni
				if(call Storage.take() == SUCCESS) {
					atomic { sending = TRUE; }
				} 	
			}	
			if(btrpkt -> node_id_stop == TOS_NODE_ID) {		//torolhetjuk az adatokat
				if(call Storage.delete((uint8_t* )btrpkt -> free) == SUCCESS) {
					atomic { sending = FALSE; }
				}
			}
		}
		return msg;
	}

	event message_t* radRecFreeMsg.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(FreeMsg)) {
			FreeMsg* btrpkt = (FreeMsg*) (call AMSend.getPayload(msg, sizeof(FreeMsg)));
			if(TOS_NODE_ID == btrpkt -> node_id) {
				if(call Storage.delete((uint8_t* )btrpkt -> free) == SUCCESS) {
				}
			}
		}
		return msg;
	}


	event void AMSend.sendDone(message_t *msg, error_t error) {	
	}
}
