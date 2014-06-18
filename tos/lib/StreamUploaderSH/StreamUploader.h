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
* Author:Andras Biro
*/
#ifndef STREAM_UPLOADER_H
#define STREAM_UPLOADER_H
#include "message.h"
#ifndef RADIO_SHORT
	#define RADIO_SHORT 1000U
#endif
#ifndef RADIO_LONG
	#define RADIO_LONG 60U
#endif
#ifndef RADIO_MIDDLE
	#define RADIO_MIDDLE 10000U
#endif
enum{
	OFF=0,
	WAIT_FOR_BS,
	WAIT_FOR_REQ,
	COMMAND_PENDING,
	SEND,
	ERASE,
	BS_ADDR=0,
	NO_BS=0,
	BS_OK=6,
	MESSAGE_SIZE=TOSH_DATA_LENGTH-4,
	//MESSAGE_SIZE=28-4,
	AM_CTRL_MSG_T=10,//Just for the MIG
	AM_DATA_MSG_T=AM_CTRL_MSG_T+1,
	AM_CTRLTS_MSG_T=AM_CTRL_MSG_T,
//	SHORT_TIME=RADIO_SHORT,//in milliseconds
//	LONG_TIME=RADIO_LONG,//in seconds
	CMD_ERASE = 0,
};

typedef nx_struct ctrl_msg_t {
	nx_uint32_t min_address;
	nx_uint32_t max_address;
	nx_uint32_t localtime;
} ctrl_msg;

typedef nx_struct ctrlts_msg_t {
	nx_uint32_t min_address;
	nx_uint32_t max_address;
	nx_uint32_t localtime;
	nx_uint32_t timestamp;
} ctrlts_msg;

typedef nx_struct data_msg_t {
	nx_uint32_t address;
	nx_int8_t data[MESSAGE_SIZE];
} data_msg;

#endif /* STREAM_UPLOADER_H */
