/*
 * Copyright (c) 2007, Vanderbilt University
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
 * Author: Krisztian Veress
 */

#ifndef __RADIOCONFIG_H__
#define __RADIOCONFIG_H__

#include <RFA1DriverLayer.h>
#include "TimerConfig.h"
#include <Si443xDriverLayer.h>

#ifndef SI443X_DEF_RFPOWER
#define SI443X_DEF_RFPOWER	7
#endif

#ifndef SI443X_DEF_CHANNEL
#define SI443X_DEF_CHANNEL	0
#endif


/* This is the default value of the TX_PWR field of the PHY_TX_PWR register. */
#ifndef RFA1_DEF_RFPOWER
#define RFA1_DEF_RFPOWER	0
#endif

/* This is the default value of the CHANNEL field of the PHY_CC_CCA register. */
#ifndef RFA1_DEF_CHANNEL
#define RFA1_DEF_CHANNEL	26
#endif


/* The number of microseconds a sending mote will wait for an acknowledgement */
#ifndef SOFTWAREACK_TIMEOUT
#define SOFTWAREACK_TIMEOUT	1000
#endif

enum {
	SI443X_TXFIFO_FULL_THRESH = 60,
	SI443X_TXFIFO_EMPTY_THRESH = 4,

	/** MUST be greater or equal to Si443xDriverConfig.headerPreloadLength() ! */
	SI443X_RXFIFO_FULL_THRESH = 55,
	
	/**	Base Frequency setting.
			Should be multiple of 156.25 Hz for band 240-480 Mhz,
			Should be multiple of 312.50 Hz for band 480-960 Mhz
			
	 Examples:
		 240 000 000.0  Hz : FREQ_10MHZ = 24, FREQ_KHZ = 0      FREQ_MILLIHZ = 0
		 334 876 562.25 Hz : FREQ_10MHZ = 33, FREQ_KHZ = 4876   FREQ_MILLIHZ = 56225
		 959 903 437.50 Hz : FREQ_10MHZ = 95, FREQ_KHZ = 9903   FREQ_MILLIHZ = 43750
	*/
	// Valid values for SI443X_BASE_FREQ_10MHZ : [24,..,95]
	SI443X_BASE_FREQ_10MHZ = 43,
	
	// Valid values for SI443X_BASE_FREQ_KHZ : [0,..,9999]
	SI443X_BASE_FREQ_KHZ = 4000,
	
	// Valid values for SI443X_BASE_FREQ_MILLIHZ : [0U,...,99999U]
	SI443X_BASE_FREQ_MILLIHZ = 0U,
	
	// Channel step size for frequency hopping in 10KHz's
	SI443X_CHANNEL_STEP_10KHZ = 100,	
};

/** You can derive more modem configuration options with the shipped Si443x Modem Configuration Excel tool. */
#define SI443X_MODEM_CONFIG_COUNT 3

#ifndef SI443X_MODEM_CONFIG
#define SI443X_MODEM_CONFIG 3
#elif SI443X_MODEM_CONFIG > SI443X_MODEM_CONFIG_COUNT
#error "You have set an invalid SI443X modem configuration!"
#endif

#define SI443X_MODEM_CONFIG_LENGTH 26
uint8_t si443x_modem_configuration[][SI443X_MODEM_CONFIG_LENGTH] = {
	{ 0x1C,0x1D,0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x25,0x2A,0x2C,0x2D,0x2E,0x30,0x32,0x33,0x34,0x35,0x58,0x69,0x6E,0x6F,0x70,0x71,0x72 },
	
	// GFSK, 250kbps, NO Manchester, AFC >1%, 150ppm crystal, CRC16
	#if ( SI443X_MODEM_CONFIG == 1 )
	{ 0x8E,0x44,0x02,0x00,0x30,0x02,0xAA,0xAB,0x14,0x74,0x50,0x28,0x05,0x27,0x8D,0x00,0x00,0x04,0x22,0xED,0x60,0x40,0x00,0x0D,0x27,0xE0 },
	#endif
	
	// GFSK, 250kbps, NO Manchester, AFC <=1%, 30ppm crystal, CRC16
	#if ( SI443X_MODEM_CONFIG == 3 )
	{ 0x8E,0x44,0x02,0x00,0x30,0x02,0xAA,0xAB,0x14,0x74,0x50,0x28,0x05,0x27,0x8D,0x00,0x00,0x0A,0x22,0xED,0x60,0x40,0x00,0x0D,0x27,0xE0 },
	#endif
	
	// OOK, 250kbps, Manchester, 400kHZ OOK BW, 150ppm crystal, CRC16
	#if ( SI443X_MODEM_CONFIG == 2 )
	{ 0x8A,0x44,0x02,0x00,0x18,0x02,0xAA,0xAB,0x15,0x57,0x50,0x18,0x02,0x26,0x8D,0x00,0x00,0x04,0x22,0xED,0x60,0x40,0x00,0x0F,0x25,0xE0 }
	#endif
};

enum
{
	/**
	 * This is the default value of the CCA_MODE field in the PHY_CC_CCA register
	 * which is used to configure the default mode of the clear channel assesment
	 */
	RFA1_CCA_MODE_VALUE = CCA_CS<<CCA_MODE0,

	/**
	 * This is the value of the CCA_THRES register that controls the
	 * energy levels used for clear channel assesment
	 */
	RFA1_CCA_THRES_VALUE = 0xC7,	//TODO to avr-libc values
	
	RFA1_PA_BUF_LT=3<<PA_BUF_LT0,
	RFA1_PA_LT=0<<PA_LT0,
};

#ifdef RFA1_RADIO_TIMER1_MCU
/**
 * This is the timer type of the radio alarm interface
 */
typedef TMcu TRadio;
/**
 * The number of radio alarm ticks per one microsecond
 */
#define RADIO_ALARM_MICROSEC	2

/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
#define RADIO_ALARM_MILLI_EXP	11

#elif defined(RFA1_RADIO_TIMER1_MICRO)
/**
 * This is the timer type of the radio alarm interface
 */
typedef TMicro TRadio;
/**
 * The number of radio alarm ticks per one microsecond
 */
#define RADIO_ALARM_MICROSEC	1

/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
#define RADIO_ALARM_MILLI_EXP	10

#else
/**
 * This is the timer type of the radio alarm interface
 */
typedef T62khz TRadio;
/**
 * The number of radio alarm ticks per one microsecond
 */
#define RADIO_ALARM_MICROSEC	0.0625

/**
 * The base two logarithm of the number of radio alarm ticks per one millisecond
 */
#define RADIO_ALARM_MILLI_EXP	6
#endif
typedef uint32_t tradio_size;

#endif//__RADIOCONFIG_H__
