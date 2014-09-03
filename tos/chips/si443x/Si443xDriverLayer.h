/*
 * Copyright (c) 2007,Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms,with or without
 * modification,are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice,this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice,this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,INCLUDING,BUT NOT
 * LIMITED TO,THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT,INCIDENTAL,SPECIAL,EXEMPLARY,OR CONSEQUENTIAL DAMAGES
 * (INCLUDING,BUT NOT LIMITED TO,PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE,DATA,OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,WHETHER IN CONTRACT,
 * STRICT LIABILITY,OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 * Author: Krisztian Veress
 */

#ifndef __SI443X_DRIVERLAYER_H__
#define __SI443X_DRIVERLAYER_H__

typedef nx_struct si443x_header_t
{
	nxle_uint8_t length;
} si443x_header_t;

typedef nx_struct si443x_footer_t {} si443x_footer_t;

typedef struct si443x_metadata_t
{
	uint8_t lqi;
	union
	{
		uint8_t power;
		uint8_t rssi;
	};
} si443x_metadata_t;

enum si443x_registers_enum
{

	SI443X_DEVSTAT = 0x02,
	SI443X_INT_1 = 0x03,
	SI443X_INT_2 = 0x04,
	SI443X_IEN_1 = 0x05,
	SI443X_IEN_2 = 0x06,
	SI443X_CTRL_1 = 0x07,
	SI443X_CTRL_2 = 0x08,
	SI443X_RSSI = 0x26,
	SI443X_CCA_THRES = 0x26,
	SI443X_PKTLEN = 0x3E,
	SI443X_XTAL_POR = 0x62,
	SI443X_TXPOWER = 0x6D,
	
	SI443X_CHANNEL_SELECT = 0x79,
	SI443X_CHANNEL_STEPSIZE = 0x7A,
	SI443X_TXFIFO_FULL = 0x7C,
	SI443X_TXFIFO_EMPTY = 0x7D,
	SI443X_RXFIFO_FULL = 0x7E,
	SI443X_FIFO = 0x7F,

};

enum si443x_register_related_enum {

	SI443X_SPI_READ = 0x00,
	SI443X_SPI_WRITE = 0x80,
	SI443X_SPI_REGMASK = 0x7F,

	SI443X_CLEAR_RX_FIFO = 1<<1,
	SI443X_CLEAR_TX_FIFO = 1<<0,
	
	SI443X_LNA = 0x18,
	SI443X_RFPOWER_MASK = 0x07,
	SI443X_FIFO_SIZE = 64,
	
	SI443X_FREQ_BAND_MISC = 0x40,
	SI443X_FREQ_HBSEL = 1<<5,
	SI443X_FREQ_BAND_MASK = 0x1F,
};

enum si443x_ctrl1_enums
{
	SI443X_CTRL1_SWRESET = 1 << 7,
	SI443X_CTRL1_TRANSMIT = 1 << 3,
	SI443X_CTRL1_RECEIVE = 1 << 2,
	SI443X_CTRL1_TUNE = 1 << 1,
	SI443X_CTRL1_READY = 1 << 0,
	SI443X_CTRL1_STANDBY = 0,
};

enum si443x_interrupt_enums
{
	SI443X_I_NONE = 0,
	SI443X_I_ALL = 0xFF,
	SI443X_I1_FIFOERROR = 1 << 7,
	SI443X_I1_TXFIFOFULL = 1 << 6,
	SI443X_I1_TXFIFOEMPTY = 1 << 5,
	SI443X_I1_RXFIFOFULL = 1 << 4,
	SI443X_I1_EXTERNAL = 1 << 3,
	SI443X_I1_PKTSENT = 1 << 2,
	SI443X_I1_PKTRECEIVED = 1 << 1,
	SI443X_I1_CRCERROR = 1 << 0,
	
	SI443X_I2_SYNCDETECT = 1 << 7,
	SI443X_I2_PREAVALID = 1 << 6,
	SI443X_I2_PREAINVALID = 1 << 5,
	SI443X_I2_RSSI = 1 << 4,
	SI443X_I2_WAKEUP = 1 << 3,
	SI443X_I2_LOWBAT = 1 << 2,
	SI443X_I2_CHIPREADY = 1 << 1,
	SI443X_I2_POR = 1 << 0,
};


#endif //__SI443X_DRIVERLAYER_H__
