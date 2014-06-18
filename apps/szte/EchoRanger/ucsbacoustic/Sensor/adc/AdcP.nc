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

#include "Adc.h"

module AdcP
{
	provides
	{
		interface Read<uint16_t>[uint8_t client];
		interface ReadNow<uint16_t>[uint8_t client];
	}

	uses
	{
		interface Atm128Adc;
		interface Atm128AdcConfig[uint8_t client];
	}
}

implementation 
{
	enum
	{
		STATE_READY = 0,
		STATE_READ_WARMUP = 1,
		STATE_READ_FINAL = 2,
		STATE_READNOW_WARMUP = 3,
		STATE_READNOW_FINAL = 4,
	};

	norace uint8_t state;
	norace uint8_t client;
	norace uint16_t data;

	task void readDone()
	{
		state = STATE_READY;
		signal Read.readDone[client](SUCCESS, data);
	}

	async event void Atm128Adc.dataReady(uint16_t d)
	{
		// we use only single shot interrupts and do some processing
		__nesc_enable_interrupt();

		if( state == STATE_READ_FINAL )
		{
			data = d;
			post readDone();
		}
		else if( state == STATE_READNOW_FINAL )
		{
			state = STATE_READY;
			signal ReadNow.readDone[client](SUCCESS, d);
		}
		else
		{
			state++;

			call Atm128Adc.getData(call Atm128AdcConfig.getPrescaler[client](), ADC_DEFAULT_TRACKHOLD_TIME, FALSE);
		}
	}

	error_t sample(uint8_t s, uint8_t c)
	{
		if( call Atm128Adc.setSource(call Atm128AdcConfig.getChannel[c](), 
			call Atm128AdcConfig.getRefVoltage[c](), FALSE) == FALSE )
		{
			--s;
		}

		client = c;
		state = s;

		call Atm128Adc.getData(call Atm128AdcConfig.getPrescaler[client](), ADC_DEFAULT_TRACKHOLD_TIME, FALSE);

		return SUCCESS;
	}

	command error_t Read.read[uint8_t c]()
	{
		return sample(STATE_READ_FINAL, c);
	}

	async command error_t ReadNow.read[uint8_t c]()
	{
		return sample(STATE_READNOW_FINAL, c);
	}

// -------  Configuration defaults (Read ground fast!)

	default async command uint8_t Atm128AdcConfig.getChannel[uint8_t c]() {
		return ATM128_ADC_SNGL_GND;
	}

	default async command uint8_t Atm128AdcConfig.getRefVoltage[uint8_t c]() {
		return ATM128_ADC_VREF_OFF;
	}

	default async command uint8_t Atm128AdcConfig.getPrescaler[uint8_t c]() {
		return ATM128_ADC_PRESCALE_2;
	}

	default event void Read.readDone[uint8_t c](error_t e, uint16_t d) { }
	default async event void ReadNow.readDone[uint8_t c](error_t e, uint16_t d) { }
}
