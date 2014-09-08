/*
 * Copyright (c) 2010, University of Szeged
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
 */

#include "TimerConfig.h"
#include "avr/boot.h"
module McuInitP @safe()
{
	provides interface Init;

	uses
	{
		interface Init as MeasureClock;
		interface Init as TimerInit;
		interface Init as AdcInit;
		interface Init as RadioInit;
	}
}

implementation
{
	error_t systemClockInit()
	{
		// set the clock prescaler
		atomic
		{
			// enable changing the prescaler
			CLKPR = 0x80;
#if PLATFORM_MHZ == 16
			if ( (boot_lock_fuse_bits_get(GET_LOW_FUSE_BITS) & 0x0F) == 2 ) //internal RC oscillator
				CLKPR = 0x0F;
			else
				CLKPR = 0x00;
#elif PLATFORM_MHZ == 8
			if ( (boot_lock_fuse_bits_get(GET_LOW_FUSE_BITS) & 0x0F) == 2 ) //internal RC oscillator
				CLKPR = 0x00;
			else
				CLKPR = 0x01;
#elif PLATFORM_MHZ == 4
			if ( (boot_lock_fuse_bits_get(GET_LOW_FUSE_BITS) & 0x0F) == 2 ) //internal RC oscillator
				CLKPR = 0x01;
			else
				CLKPR = 0x02;
#elif PLATFORM_MHZ == 2
			if ( (boot_lock_fuse_bits_get(GET_LOW_FUSE_BITS) & 0x0F) == 2 ) //internal RC oscillator
				CLKPR = 0x02;
			else
				CLKPR = 0x03;
#elif PLATFORM_MHZ == 1
			if ( (boot_lock_fuse_bits_get(GET_LOW_FUSE_BITS) & 0x0F) == 2 ) //internal RC oscillator
				CLKPR = 0x03;
			else
				CLKPR = 0x04;
#else
	#error "Unsupported MHZ"
#endif
		}

		return SUCCESS;
	}

	command error_t Init.init()
	{
		error_t ok;
#ifdef BOOTLOADER_INTERRUPTS
		uint8_t temp;
#endif
		
		DRTRAM0 |= 1<<ENDRT;
		DRTRAM1 |= 1<<ENDRT;
		DRTRAM2 |= 1<<ENDRT;
		DRTRAM3 |= 1<<ENDRT;
#ifndef ENABLE_JTAG_DEBUG
		MCUCR |= 1<<JTD;
		MCUCR |= 1<<JTD;
#else
		#warning "JTAG DEBUG ENABLED (ENABLE_JTAG_DEBUG)"
#endif
		
#ifdef BOOTLOADER_INTERRUPTS
		#warning "Interrupt table in bootloader area"
		temp = MCUCR;
		MCUCR = temp | (1<<IVCE);
		MCUCR = temp | (1<<IVSEL);
#endif
		
		ok = systemClockInit();
		ok = ecombine(ok, call MeasureClock.init());
		ok = ecombine(ok, call TimerInit.init());
		ok = ecombine(ok, call AdcInit.init());
		ok = ecombine(ok, call RadioInit.init());

		return ok;
	}

	default command error_t TimerInit.init() { return SUCCESS; }
	default command error_t AdcInit.init() { return SUCCESS; }
}
