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

configuration WireAdcStreamP
{
	provides
	{
		interface ReadStream<uint16_t>[uint8_t stream];
	}

	uses
	{
		interface Atm128AdcConfig[uint8_t stream];
		interface Resource[uint8_t stream];
	}
}

implementation
{
	enum {
		ADC_STREAMS = uniqueCount(UQ_ADC_READSTREAM),
		ADC_ADAPTER = unique(UQ_ATM128ADC_ADAPTER),
	};

	components Atm128AdcC, AdcStreamP, PlatformC, 
		new ArbitratedReadStreamC(ADC_STREAMS, uint16_t);

	Resource = ArbitratedReadStreamC;
	ReadStream = ArbitratedReadStreamC;
	Atm128AdcConfig = AdcStreamP;

	ArbitratedReadStreamC.Service -> AdcStreamP;

	AdcStreamP.Atm128Adc -> Atm128AdcC.Atm128Adc[ADC_ADAPTER];
	AdcStreamP.Atm128Calibrate -> PlatformC;
}
