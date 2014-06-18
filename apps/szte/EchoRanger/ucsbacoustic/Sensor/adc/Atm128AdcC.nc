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

configuration Atm128AdcC
{
	provides
	{
		interface Resource[uint8_t client];
		interface Atm128Adc[uint8_t adapter];
	}
	uses
	{
		interface ResourceConfigure[uint8_t client];
	}
}
implementation
{
	components Atm128AdcP, HplAtm128AdcC, PlatformC, MainC, McuInitC,
		new RoundRobinArbiterC(UQ_ATM128ADC_RESOURCE) as ArbiterC,
		new AsyncStdControlPowerManagerC() as PowerManagerC;

	Resource = ArbiterC;
	ResourceConfigure = ArbiterC;
	Atm128Adc = Atm128AdcP;

	McuInitC.AdcInit -> Atm128AdcP;

	Atm128AdcP.HplAtm128Adc -> HplAtm128AdcC;
	Atm128AdcP.Atm128Calibrate -> PlatformC;

	PowerManagerC.AsyncStdControl -> Atm128AdcP;
	PowerManagerC.ResourceDefaultOwner -> ArbiterC;
}
