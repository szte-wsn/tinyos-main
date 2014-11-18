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
#include "RFA1Radio.h"
module NullC @safe()
{
  uses interface Boot;
	uses interface Atm128Calibrate;
}
implementation
{
	enum{
		CHANNEL = 17,
		// this disables the RFA1RadioOffP component
		RFA1RADIOON = unique("RFA1RadioOn"),
	};
	
  event void Boot.booted() {
		uint32_t ubrr0 = call Atm128Calibrate.baudrateRegister(1000000UL);
		UBRR0L = ubrr0;
		UBRR0H = ubrr0 >> 8;
		UCSR0A |= (1<<U2X0);
		UCSR0C |=  (1<<UCSZ01);
		UCSR0B |= (1<<TXEN0);
		
		PHY_CC_CCA = RFA1_CCA_MODE_VALUE | CHANNEL;
		TRX_STATE = CMD_RX_ON;
		while ( (TRX_STATUS & RFA1_TRX_STATUS_MASK) != RX_ON )
			;
		
		
		/*
		 * This assembly part stores the PHY_RSSI register in the buffer at 500kHz (which is the update frequency of the register)
		 * On 8MHz and faster, it also masks the upper (random and crc) bits
		 * The register updates every 2us which is 500kHz. So, the waiting goes like this:
		 * 4MHz: the loop is 8 cycle, no need to nop, no place for and
		 * 8MHz: the loop is 10 cycle, 1 cycle and,  5 nop needed
		 * 16MHz the loop is 12 cycle, 1 cycle and, 19 nop needed
		 */
		asm volatile (
			"1: lds __tmp_reg__, 0x146\n\t" //1:__tmp_reg__ = PHY_RSSI; //6clk on 16MHz, 4clk on 8MHz, 2clk on 4MHz. meaning: 
			"and __tmp_reg__, %0\n\t" //__tmp_reg__ &= RFA1_RSSI_MASK; //1clk
			"sts 0xc6, __tmp_reg__\n\t" //UDR0 = __tmp_reg__; //2clk
			"nop\n\t" //1clk
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
			"nop\n\t"
		"jmp 1b\n\t" //goto 1; //2clk
		:: "r" (RFA1_RSSI_MASK)
		);
  }
}

