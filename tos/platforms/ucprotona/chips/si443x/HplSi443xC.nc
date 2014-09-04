/*
 * Copyright (c) 2010, Univeristy of Szeged
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
 * - Neither the name of the copyright holder nor the names of
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
 *
 * Author: Miklos Maroti
 * Author: Andras Biro
 */

#include <RadioConfig.h>

configuration HplSi443xC
{
	provides
	{
		interface GeneralIO as NSEL;
		interface GeneralIO as SDN;
		
#ifdef SI443X_GPIOCAPTURE		
		interface GpioCapture as IRQ;
#else
		interface GpioInterrupt as IRQ;
#endif
 	    
		interface Resource as SpiResource;
		interface FastSpiByte;
		interface Alarm<TRadio, tradio_size> as Alarm;
		interface LocalTime<TRadio> as LocalTimeRadio;
	}
}
implementation
{
	components AtmegaGeneralIOC as IO, new NoPinC();
	NSEL = IO.PortF0;
	SDN = NoPinC;
    
	components Atm128SpiC as SpiC;
	SpiResource = SpiC.Resource[unique("Atm128SpiC.Resource")];
	FastSpiByte = SpiC;

	components new Alarm62khz32C() as AlarmC;
	Alarm = AlarmC;
 
	components LocalTime62khzC as LocalTimeC;
	LocalTimeRadio = LocalTimeC;

	components AtmegaPinChange0C;
	
#ifdef SI443X_GPIOCAPTURE
	components HplAtmRfa1Timer1C, HplSi443xP;
	HplSi443xP.AtmegaCapture -> HplAtmRfa1Timer1C;
	HplSi443xP.AtmegaCounter -> HplAtmRfa1Timer1C;
	
	IRQ = HplSi443xP.GpioCapture;
	HplSi443xP.IRQ -> AtmegaPinChange0C.GpioInterrupt[4];
	HplSi443xP.LocalTime -> LocalTimeC;

	HplSi443xP.GPIO -> IO.PortD4;

	components RealMainP;
	RealMainP.PlatformInit -> HplSi443xP;
	
#else
	IRQ = AtmegaPinChange0C.GpioInterrupt[4];

#endif

}
