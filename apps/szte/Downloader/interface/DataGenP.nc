#include "Sender.h"

module DataGenP {
	uses{
		interface Timer<TMilli> as Timer_mes;
		interface Leds;
		interface Boot;
		interface SplitControl;
		interface Storage;
	}
}
implementation {

	uint8_t buffer[MEASUREMENT_LENGTH];
	uint16_t c;		//teszteleshez

	task void mesCreate() {		//adatfeltoltes
		int i = 0;
		int szamol = 0;
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
}
