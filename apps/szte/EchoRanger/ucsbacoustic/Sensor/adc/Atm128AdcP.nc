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
* Author: Miklos Maroti
*/

#include "Atm128Adc.h"

module Atm128AdcP
{
	provides
	{
		interface Init;
		interface AsyncStdControl;
		interface Atm128Adc[uint8_t adapter];
	}
	uses 
	{
		interface HplAtm128Adc;
		interface Atm128Calibrate;
	}
}

implementation
{
	command error_t Init.init()
	{
		Atm128Adcsra_t adcsr;

		adcsr.aden = ATM128_ADC_ENABLE_OFF;
		adcsr.adsc = ATM128_ADC_START_CONVERSION_OFF;
#if defined(__AVR_ATmega1281__) || defined(__AVR_ATmega128RFA1__)
		adcsr.adate = ATM128_ADC_FREE_RUNNING_OFF;
#else
		adcsr.adfr = ATM128_ADC_FREE_RUNNING_OFF; 
#endif
		adcsr.adif = ATM128_ADC_INT_FLAG_OFF;
		adcsr.adie = ATM128_ADC_INT_ENABLE_OFF;
		adcsr.adps = ATM128_ADC_PRESCALE_2;

		call HplAtm128Adc.setAdcsra(adcsr);
		return SUCCESS;
	}

	async command error_t AsyncStdControl.start()
	{
		call HplAtm128Adc.disableAdc();
		return SUCCESS;
	}

	async command error_t AsyncStdControl.stop()
	{
		call HplAtm128Adc.disableAdc();
		return SUCCESS;
	}

	norace uint8_t adapter;

	async command bool Atm128Adc.setSource[uint8_t adap](uint8_t channel, uint8_t refVoltage, bool leftJustify)
	{
		uint8_t prevChannel = call HplAtm128Adc.getChannel();
    uint8_t prevRef = call HplAtm128Adc.getRef();
		bool precise;


		precise = (refVoltage == prevRef) 
			&& (channel == prevChannel || channel <= ATM128_ADC_SNGL_ADC7 || channel >= ATM128_ADC_SNGL_1_23);

		call HplAtm128Adc.setChannel(channel);
    call HplAtm128Adc.setRef(refVoltage);
    call HplAtm128Adc.setAdlar(leftJustify);

		return precise;
	}

	async command void Atm128Adc.getData[uint8_t adap](uint8_t prescaler, uint8_t trackHoldTime, bool multiple)
	{
		Atm128Adcsra_t adcsr;
		
		adapter = adap;

		adcsr.aden = ATM128_ADC_ENABLE_ON;
		adcsr.adsc = ATM128_ADC_START_CONVERSION_ON;
		adcsr.adif = ATM128_ADC_INT_FLAG_ON; // clear any stale flag
		adcsr.adie = ATM128_ADC_INT_ENABLE_ON;

#if defined(__AVR_ATmega1281__) || defined(__AVR_ATmega128RFA1__)
		adcsr.adate = multiple;
#else
		adcsr.adfr = multiple;
#endif

		if (prescaler == ATM128_ADC_PRESCALE)
			prescaler = call Atm128Calibrate.adcPrescaler();
		adcsr.adps = prescaler ;

		call HplAtm128Adc.setTrackHoldTime(trackHoldTime);
		call HplAtm128Adc.setAdcsra(adcsr);
	}

	enum {
		ADC_ADAPTERS = uniqueCount(UQ_ATM128ADC_ADAPTER),
	};

	async event void HplAtm128Adc.dataReady(uint16_t data)
	{
		// to make this special case even faster
		if( ADC_ADAPTERS == 1 )
			signal Atm128Adc.dataReady[0](data);
		else
			signal Atm128Adc.dataReady[adapter](data);
	}

	async command void Atm128Adc.cancel[uint8_t adap]()
	{
		call HplAtm128Adc.cancel();
	}

	default async event void Atm128Adc.dataReady[uint8_t adap](uint16_t data)
	{
	}
}
