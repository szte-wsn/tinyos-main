#include "SendData.h"

module SendDataP {
	uses{
		interface Timer<TMilli> as Timer_mes;
		interface Timer<TMilli> as Timer_login;
		interface Leds;
		interface Boot;
		interface SplitControl;
		interface Receive as radRecGetSliceMsg; 
		interface Receive as radRecCommandMsg; 
		interface AMSend;

		interface Storage;
	}
}
implementation {

	data_t buffer[MAX_MEASUREMENT_NUMBER];
	
	uint8_t mes_id;
	uint16_t c;		//teszteleshez
	message_t pkt;


	task void feltolt() {
		int i = 0;
		int j = 0;
		int szamol = 1;
		for(i = 0; i < MAX_MEASUREMENT_NUMBER; i++) {
			for(j = 0; j < MEASUREMENT_LENGTH; j++) {
				buffer[i].mes_id = i;
				buffer[i].data[j] = szamol;
				szamol = szamol + 1;
			}
		}
		call Timer_mes.startPeriodic(TIMER_PERIOD_MILLI);
	}

	event void Boot.booted() {
		mes_id = 0;
		call SplitControl.start();		
	}
	

	event void SplitControl.startDone(error_t error) {
		call Timer_login.startPeriodic(TIMER_LOGIN_MILLI);
		post feltolt();	
	}

	event void SplitControl.stopDone(error_t error) {
	}

	event void Timer_mes.fired() {
		if(call Storage.store(buffer[mes_id].data)==SUCCESS) {	//amig nincs tele addig rakjuk a bufferbe az adatokat
			c = c + 1;
			call Leds.set(c);		//teszteleshez: kijelzi, hogy epp merest tesz be a bufferbe
			mes_id = mes_id + 1;
		} 
	}

	event void Timer_login.fired() {	//elkuldjuk a base-nek, hogy aktivak vagyunk
		LoginMoteMsg* btrpkt = (LoginMoteMsg*) (call AMSend.getPayload(&pkt, sizeof(LoginMoteMsg)));
		btrpkt -> node_id = TOS_NODE_ID;
		if(call AMSend.send(1, &pkt, sizeof(LoginMoteMsg))==SUCCESS) { 
		}
	}

	event void Storage.takeDone() {		//ha minden adatot a bufferbol kikuldtunk
	}

	event void Storage.deleteDone() {	//minden adatot torolni a bufferbol
		c = 0;
		mes_id = 0;
		
		call Timer_login.startPeriodic(TIMER_LOGIN_MILLI);
		post feltolt();
	}

	event void Storage.commEndDone() {
	}

	event void Storage.sendMeasurementNumberDone() {
		if(call Storage.take()==SUCCESS) {
		} 	
	}

	event message_t* radRecGetSliceMsg.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(GetSliceMsg)) {
			GetSliceMsg* btrpkt = (GetSliceMsg*) (call AMSend.getPayload(msg, sizeof(GetSliceMsg)));
			if(call Storage.getSlice(btrpkt -> mes_id, btrpkt -> slice) == SUCCESS) {
			} 
		}
		return msg;
	}

	event message_t* radRecCommandMsg.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(CommandMsg)) {		
			CommandMsg* btrpkt = (CommandMsg*) (call AMSend.getPayload(msg, sizeof(CommandMsg)));
			if(btrpkt -> node_id_start == TOS_NODE_ID) {			//elkezd adni
				if(call Storage.sendMeasurementNumber()==SUCCESS) {
					call Timer_login.stop();
					call Timer_mes.stop();	//addig ne merjen tovabb, amig nem uritettuk ki a buffert
				} 	
			}
			if(btrpkt -> node_id_stop == TOS_NODE_ID) {		//torolhetjuk az adatokat
				if(call Storage.delete() == SUCCESS) {
				}
			}
		}
		return msg;
	}


	event void AMSend.sendDone(message_t *msg, error_t error) {	
	}
}
