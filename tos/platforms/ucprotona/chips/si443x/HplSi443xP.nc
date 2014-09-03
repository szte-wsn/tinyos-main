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
 */

#include <RadioConfig.h>
#include <TimerConfig.h>

module HplSi443xP
{
	provides
	{
		interface Init;
		interface GpioCapture;
	}

	uses
	{
		interface GpioInterrupt as IRQ;
		interface LocalTime<TRadio>;

		// we need to use these to get precise timing
		interface GeneralIO as GPIO;
		interface AtmegaCapture<uint16_t>;
		interface AtmegaCounter<uint16_t>;
	}
}

#include "HplAtmRfa1Timer.h"

implementation
{
	command error_t Init.init()
	{
		call AtmegaCapture.setMode(ATMRFA1_CAP16_RISING_EDGE);
		call AtmegaCapture.start();
		return SUCCESS;
	}

	async command error_t GpioCapture.captureRisingEdge()
	{
		return call IRQ.enableRisingEdge();
	}

	async command error_t GpioCapture.captureFallingEdge()
	{
		return call IRQ.enableFallingEdge();
	}

	async command void GpioCapture.disable()
	{
		call IRQ.disable();
	}

	async event void IRQ.fired()
	{
		uint16_t now;
		uint16_t elapsed;

		atomic
		{
			elapsed = call AtmegaCounter.get() - call AtmegaCapture.get();
			now = call LocalTime.get();
		}

		now -= elapsed >> (MCU_TIMER_MHZ_LOG2 + 10 - 6);
		signal GpioCapture.captured(now);
	}
	
	async event void AtmegaCapture.fired() { }

	async event void AtmegaCounter.overflow() { }
}
