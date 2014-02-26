// $Id: hardware.h,v 1.5 2010-06-29 22:07:50 scipio Exp $

/*
 * Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 * - Neither the name of the copyright holders nor the names of
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * $Id: hardware.h,v 1.5 2010-06-29 22:07:50 scipio Exp $
 *
 */

#ifndef __HARDWARE_H__
#define __HARDWARE_H__

#include <atm128hardware.h>
#include <avrhardware.h>

#ifndef MHZ
/* Clock rate is ~8MHz except if specified by user 
   (this value must be a power of 2, see MicaTimer.h and MeasureClockC.nc) */
#define MHZ 8
#endif 

typedef uint32_t in_flash_addr_t;
typedef uint32_t ex_flash_addr_t;

static inline void wait( uint16_t dt ) {
  /* In most cases (constant arg), the test is elided at compile-time */
  if (dt)
    /* loop takes 8 cycles. this is 1uS if running on an internal 8MHz
       clock, and 1.09uS if running on the external crystal. */
    asm volatile (
      "1:       sbiw    %0,1\n"
      " adiw    %0,1\n"
      " sbiw    %0,1\n"
      " brne    1b" : "+w" (dt));
}

// LED assignments
TOSH_ASSIGN_PIN(RED_LED, D, 7);
TOSH_ASSIGN_PIN(GREEN_LED, D, 6);
TOSH_ASSIGN_PIN(YELLOW_LED, E, 2);
//SPI assignments
TOSH_ASSIGN_PIN(SPI_SS, B, 0);
TOSH_ASSIGN_PIN(SPI_CLK,  B, 1);
TOSH_ASSIGN_PIN(SPI_MOSI,  B, 2);
TOSH_ASSIGN_PIN(SPI_MISO,  B, 3);
// Flash assignments
TOSH_ASSIGN_PIN(FLASH_CS, B, 0); //same as SPI SS
TOSH_ASSIGN_DUMMY_PIN(FLASH_HOLD,  1);
TOSH_ASSIGN_DUMMY_PIN(FLASH_POWER, 1);

TOSH_ASSIGN_PIN(RADIO_CS, F, 0);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();

  TOSH_MAKE_RADIO_CS_OUTPUT();
  TOSH_SET_RADIO_CS_PIN();
}

enum {
  VOLTAGE_PORT = 30,
  VTHRESH = 0x1cf, // 2.7V
};

#endif




