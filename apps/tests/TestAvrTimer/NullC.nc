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

#ifdef PRECISION_MCU
	#define TTest TMcu
#elif defined(PRECISION_MICRO)
	#define TTest TMicro
#elif defined(PRECISION_MILLI)
	#define TTest TMilli
#endif

module NullC @safe()
{
	uses interface Boot;
	uses interface Leds;
	uses interface DiagMsg;
	uses interface Alarm<TTest, uint32_t>;
	uses interface Counter<TTest, uint32_t>;
}
implementation
{
	enum{
		TEST_ALARM = 10,
		TEST_COUNT = 10000,
	};
	int32_t counterNonAtomicMin, counterNonAtomicMax;
	int32_t counterAtomicMin, counterAtomicMax;
	int32_t counterOPMin, counterOPMax;
	int32_t counterOMin, counterOMax;
	int32_t alarmErrorMin, alarmErrorMax;
	uint32_t alarmShouldFireAt;
	uint16_t testCounter;
	
	inline void updateMinMax(uint32_t *min, uint32_t *max, uint32_t val){
		if( *min > val )
			*min = val;
		else if( *max < val )
			*max = val;
	}
	
	task void doTest(){
		uint32_t a, b;
		uint32_t diff;
		a = call Counter.get();
		b = call Counter.get();
		updateMinMax(&counterNonAtomicMin, &counterNonAtomicMax, (uint32_t)(b-a));
		atomic{
			a = call Counter.get();
			b = call Counter.get();
			if( call Counter.isOverflowPending() ){
				updateMinMax(&counterOPMin, &counterOPMin, call Counter.get());
			}
		}
		updateMinMax(&counterAtomicMin, &counterAtomicMax, (uint32_t)(b-a));
		alarmShouldFireAt = call Alarm.getNow();
		call Alarm.startAt( alarmShouldFireAt, TEST_ALARM);
		alarmShouldFireAt += TEST_ALARM;
	}
	
	inline void reset(){
		testCounter = 0;
		counterNonAtomicMin = counterAtomicMin = counterOPMin = counterOMin = alarmErrorMin = 0xffffffff;
		counterNonAtomicMax = counterAtomicMax = counterOPMax = counterOMax = alarmErrorMax = 0;
	}
	
	inline void reportLine(char* id, uint32_t min, uint32_t max){
		if( call DiagMsg.record() ){
			call DiagMsg.str(id);
			call DiagMsg.uint32(min);
			call DiagMsg.uint32(max);
			call DiagMsg.send();
		}
	}
	
	task void report(){
		reportLine("Time", call Counter.get(), call Alarm.getNow());
		reportLine(counterNonAtomicMax>40?"CNA!":"CNA", counterNonAtomicMin, counterNonAtomicMax);
		reportLine(counterAtomicMax>40?"CA!":"CA", counterAtomicMin, counterAtomicMax);
		reportLine(counterOPMin<0xffffffff?"COP!":"COP", counterOPMin, counterOPMax);
		reportLine(counterOMin<0xffffffff?"CO!":"CO", counterOMin, counterOMax);
		reportLine(alarmErrorMax>150?"AE!":"AE", alarmErrorMin, alarmErrorMax);
		reset();
		post doTest();
	}
	
	async event void Alarm.fired(){
		updateMinMax(&alarmErrorMin, &alarmErrorMax, (uint32_t)(call Alarm.getNow()-alarmShouldFireAt));
		if( ++testCounter < TEST_COUNT )
			post doTest();
		else
			post report();
	}
	
	event void Boot.booted() {
		reset();
		post doTest();
	}
	
	async event void Counter.overflow(){
		updateMinMax(&counterOMin, &counterOMax, call Counter.get());
	}
}

