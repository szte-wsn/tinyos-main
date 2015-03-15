/*
 * Copyright (c) 2014, University of Szeged
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

#include "packet.hpp"
#include <cstring>
#include <vector>
#include <memory>
#include <cmath>

// ------- TosMsg

uint16_t read_uint16(std::vector<unsigned char>::const_iterator pos) {
	uint16_t value = *pos;
	value <<= 8;
	value += *(pos + 1);
	return value;
}

uint32_t read_uint32(std::vector<unsigned char>::const_iterator pos) {
	uint32_t value = *pos;
	value <<= 8;
	value += *(pos + 1);
	value <<= 8;
	value += *(pos + 2);
	value <<= 8;
	value += *(pos + 3);
	return value;
}

TosMsg::TosMsg(bool ignore)
	: sub_in(bind(&TosMsg::decode, this)),
	in(bind(&TosMsg::encode, this)), ignore(ignore) {
}

void TosMsg::decode(const std::vector<unsigned char> &raw) {
	if (raw[0] != 0) {
		if (ignore)
			return;
		else
			runtime_error("Invalid TOS packet type", raw);
	}

	if (raw.size() < 8)
		runtime_error("Invalid TOS packet header", raw);

	uint8_t len = read_uint8(raw.begin() + 5);
	if (static_cast<unsigned int>(len) + 8 != raw.size())
		runtime_error("Invalid TOS packet length", raw);

	Packet packet;
	packet.dst = read_uint16(raw.begin() + 1);
	packet.src = read_uint16(raw.begin() + 3);
	packet.group = read_uint8(raw.begin() + 6);
	packet.type = read_uint8(raw.begin() + 7);

	// timesync message
	if (packet.type != 0x3d) {
		packet.ts_valid = false;
		packet.ts_offset = 0;
		packet.payload.insert(packet.payload.begin(), raw.begin() + 8, raw.end());
	}
	else {
		if (len < 5)
			runtime_error("Invalid TOS timesync packet", raw);

		packet.payload.insert(packet.payload.begin(), raw.begin() + 8, raw.end() - 5);
		packet.type = read_uint8(raw.end() - 5);
		packet.ts_offset = read_int32(raw.end() - 4);
		packet.ts_valid = packet.ts_offset != 0x8000000;
	}

	out.send(packet);
}

void TosMsg::encode(const TosMsg::Packet &packet) {
}

std::ostream& operator <<(std::ostream& stream, const TosMsg::Packet &packet) {
	stream << std::dec;
	stream << "dst=" << static_cast<int>(packet.dst);
	stream << " src=" << static_cast<int>(packet.src);
	stream << " grp=" << static_cast<int>(packet.group);
	stream << " typ=" << static_cast<int>(packet.type);
	if (packet.ts_valid)
		stream << " tso=" << packet.ts_offset;
	stream << " " << packet.payload;
	return stream;
}

// ------- RipsMsg

RipsMsg::RipsMsg() : in(bind(&RipsMsg::decode, this)) {
}

void RipsMsg::decode(const TosMsg::Packet &tos) {
	if (tos.type != 0x06 && tos.type != 0x08)
		return;

	Packet packet;
	packet.nodeid = tos.src;
	packet.slot = read_uint8(tos.payload.begin());

	if (tos.type == 0x08) {
		if (tos.payload.size() % 3 != 1)
			runtime_error("Invalid RipsMsg length", tos);

		unsigned int third = (tos.payload.size() - 1) / 3;
		for (unsigned int i = 0; i < third; i++) {
			Measurement mnt;
			mnt.period = read_uint8(tos.payload.begin() + 1 + i);
			mnt.phase = read_uint8(tos.payload.begin() + 1 + third + i);
			mnt.rssi1 = (read_uint8(tos.payload.begin() + 1 + 2 * third + i) >> 4) & 0x0F ;
			mnt.rssi2 = (read_uint8(tos.payload.begin() + 1 + 2 * third + i)     ) & 0x0F ;
			if (mnt.period != 0 && mnt.phase >= mnt.period)
				std::cerr << "Invalid RipsMsg phase: " << mnt.phase << "/" << mnt.period << std::endl;
			packet.measurements.push_back(mnt);
		}
	} else if(tos.type == 0x06) {
		if (tos.payload.size() % 2 != 1)
			runtime_error("Invalid RipsMsg length", tos);

		unsigned int half = (tos.payload.size() - 1) / 2;
		for (unsigned int i = 0; i < half; i++) {
			Measurement mnt;
			mnt.period = read_uint8(tos.payload.begin() + 1 + i);
			mnt.phase = read_uint8(tos.payload.begin() + 1 + half + i);
			mnt.rssi1 = -1 ;
			mnt.rssi2 = -1 ;
			if (mnt.period != 0 && mnt.phase >= mnt.period)
				std::cerr << "Invalid RipsMsg phase: " << mnt.phase << "/" << mnt.period << std::endl;
			packet.measurements.push_back(mnt);
		}
	}
	out.send(packet);
}

std::ostream& operator <<(std::ostream& stream, const RipsMsg::Packet &packet) {
	stream << std::dec;
	stream << packet.nodeid << ", " << packet.slot;
	for (RipsMsg::Measurement mnt : packet.measurements)
		stream << ",\t" << mnt.phase << ", " << mnt.period;
	return stream;
}

// ------- RipsDat

std::vector<std::vector<uint8_t>> RipsDat::FOUR_MOTE = {
	//  0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15
	{SSYN,  TX1,   RX,   RX, RSYN,  TX1,   RX,   RX, RSYN,  TX1,   RX,   RX, RSYN,  TX1,  TX1,  TX1},
	{RSYN,  TX2,  TX1,  TX1, SSYN,   RX,  TX1,   RX, RSYN,   RX,  TX1,   RX, RSYN,  TX2,   RX,   RX},
	{RSYN,   RX,  TX2,   RX, RSYN,  TX2 , TX2 , TX1, SSYN,   RX,   RX,  TX1, RSYN,   RX,  TX2,   RX},
	{RSYN,   RX,   RX,  TX2, RSYN,   RX,   RX,  TX2, RSYN,  TX2,  TX2,  TX2, SSYN,   RX,   RX,  TX2}
};

std::vector<std::vector<uint8_t>> RipsDat::SIX_MOTE = {
	//    0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19    20    21    22    23    24    25    26    27    28    29    30    31    32    33    34    35    36    37    38    39    40    41
	{  SSYN,  TX1,   RX,   RX,   RX,   RX,   W1, RSYN,  TX1,   RX,   RX,   RX,   RX,   W1, RSYN,  TX1,   RX,   RX,   RX,   RX,   W1, RSYN,  TX1,   RX,   RX,   RX,   RX,   W1, RSYN,  TX1,   RX,   RX,   RX,   RX,   W1, RSYN,  TX2,  TX2,  TX2,  TX2,  TX2,   W1},
	{  RSYN,  TX2,  TX1,  TX1,  TX1,  TX1,   W1, SSYN,   RX,  TX2,   RX,   RX,   RX,   W1, RSYN,   RX,  TX2,   RX,   RX,   RX,   W1, RSYN,   RX,  TX2,   RX,   RX,   RX,   W1, RSYN,   RX,  TX2,   RX,   RX,   RX,   W1, RSYN,  TX1,   RX,   RX,   RX,   RX,   W1},
	{  RSYN,   RX,  TX2,   RX,   RX,   RX,   W1, RSYN,  TX2,  TX1,  TX1,  TX1,  TX1,   W1, SSYN,   RX,   RX,  TX2,   RX,   RX,   W1, RSYN,   RX,   RX,  TX2,   RX,   RX,   W1, RSYN,   RX,   RX,  TX2,   RX,   RX,   W1, RSYN,   RX,  TX1,   RX,   RX,   RX,   W1},
	{  RSYN,   RX,   RX,  TX2,   RX,   RX,   W1, RSYN,   RX,   RX,  TX2,   RX,   RX,   W1, RSYN,  TX2,  TX1,  TX1,  TX1,  TX1,   W1, SSYN,   RX,   RX,   RX,  TX2,   RX,   W1, RSYN,   RX,   RX,   RX,  TX2,   RX,   W1, RSYN,   RX,   RX,  TX1,   RX,   RX,   W1},
	{  RSYN,   RX,   RX,   RX,  TX2,   RX,   W1, RSYN,   RX,   RX,   RX,  TX2,   RX,   W1, RSYN,   RX,   RX,   RX,  TX2,   RX,   W1, RSYN,  TX2,  TX1,  TX1,  TX1,  TX1,   W1, SSYN,   RX,   RX,   RX,   RX,  TX2,   W1, RSYN,   RX,   RX,   RX,  TX1,   RX,   W1},
	{  RSYN,   RX,   RX,   RX,   RX,  TX2,   W1, RSYN,   RX,   RX,   RX,   RX,  TX2,   W1, RSYN,   RX,   RX,   RX,   RX,  TX2,   W1, RSYN,   RX,   RX,   RX,   RX,  TX2,   W1, RSYN,  TX2,  TX1,  TX1,  TX1,  TX1,   W1, SSYN,   RX,   RX,   RX,   RX,  TX1,   W1}
};

std::vector<std::vector<uint8_t>> RipsDat::PHASEMAP_TEST_4 = {
	//   0     1     2     3     4     5
	{ RSYN,  TX1,  W10, RSYN},
	{ RSYN,  TX2,  W10, RSYN},
	{ SSYN,   RX,  W10, RSYN},
	{ RSYN,   RX,  W10, SSYN}
};

std::vector<std::vector<uint8_t>> RipsDat::PHASEMAP_TEST_5 = {
	//   0     1     2     3     4     5
	{ RSYN,  TX1,  W10, RSYN, RSYN},
	{ RSYN,  TX2,  W10, RSYN, RSYN},
	{ SSYN,   RX,  W10, RSYN, RSYN},
	{ RSYN,   RX,  W10, SSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, SSYN}
};

std::vector<std::vector<uint8_t>> RipsDat::PHASEMAP_TEST_6 = {
	//   0     1     2     3     4     5
	{ RSYN,  TX1,  W10, RSYN, RSYN, RSYN},
	{ RSYN,  TX2,  W10, RSYN, RSYN, RSYN},
	{ SSYN,   RX,  W10, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, SSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, SSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, SSYN}
};

std::vector<std::vector<uint8_t>> RipsDat::PHASEMAP_TEST_12 = {
	//   0     1     2     3     4     5     6     7     8     9    10    11
	{ RSYN,  TX1,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,  TX2,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ SSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN}
};

std::vector<std::vector<uint8_t>> RipsDat::PHASEMAP_TEST_18 = {
	//   0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17
	{ RSYN,  TX1,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,  TX2,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ SSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN, RSYN},
	{ RSYN,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, RSYN, SSYN}
};

std::vector<std::vector<uint8_t>> RipsDat::LOC_TEST_9_GRID = {
	//0      1      2      3      4      5      6      7      8      9      10     11     12     13     14     15     16     17     18     19
	{ RSYN , TX1  , RSYN , TX1  , RSYN , TX1  , RSYN , TX1  , RSYN , TX1  , RSYN , TX1  , RSYN , TX1  , RSYN , TX1  , RSYN , TX1  , RSYN , TX1  },
	{ RSYN , TX2  , RSYN , TX2  , RSYN , TX2  , RSYN , TX2  , RSYN , TX2  , RSYN , TX2  , RSYN , TX2  , RSYN , TX2  , RSYN , TX2  , RSYN , TX2  },
	{ SSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , NTRX },
	{ RSYN , NTRX , SSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   },
	{ RSYN , RX   , RSYN , NTRX , SSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   },
	{ RSYN , RX   , RSYN , RX   , RSYN , NTRX , SSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   },
	{ RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , NTRX , SSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   },
	{ RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , NTRX , SSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   },
	{ RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , NTRX , SSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   },
	{ RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , NTRX , SSYN , RX   , RSYN , RX   , RSYN , RX   },
	{ RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , NTRX , SSYN , RX   , RSYN , RX   },
	{ RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , RX   , RSYN , NTRX , SSYN , RX   }
};

std::vector<std::vector<uint8_t>> RipsDat::LOC_MULT_TX = {
	{TX1,	TX1,	TX1,	NTRX,	NTRX,	NTRX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{TX2,	NTRX,	NTRX,	TX1,	TX1,	NTRX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{NTRX,	TX2,	NTRX,	TX2,	NTRX,	TX1,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{NTRX,	NTRX,	TX2,	NTRX,	TX2,	TX2,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN}
};

std::vector<std::vector<uint8_t>> RipsDat::LOC_4TX_4ANCHORRX = {
	{TX1,	TX1,	TX1,	NTRX,	NTRX,	NTRX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{TX2,	NTRX,	NTRX,	TX1,	TX1,	NTRX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{NTRX,	TX2,	NTRX,	TX2,	NTRX,	TX1,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{NTRX,	NTRX,	TX2,	NTRX,	TX2,	TX2,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN}
};

std::vector<std::vector<uint8_t>> RipsDat::LOC_4TX_NOANCHORRX = {
	{TX1,	TX1,	TX1,	NTRX,	NTRX,	NTRX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{TX2,	NTRX,	NTRX,	TX1,	TX1,	NTRX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{NTRX,	TX2,	NTRX,	TX2,	NTRX,	TX1,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{NTRX,	NTRX,	TX2,	NTRX,	TX2,	TX2,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN},
	{RX,	RX,	RX,	RX,	RX,	RX,	W100,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN}
};

std::vector<std::vector<uint8_t>> RipsDat::PHASEMAP_TEST_8 = {
	{ RSYN,  TX1,  TX1,  W10, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,  TX2,  TX2,  W10, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ SSYN,   RX,   RX,  W10, RSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,   RX,  W10, SSYN, RSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,   RX,  W10, RSYN, SSYN, RSYN, RSYN, RSYN},
	{ RSYN,   RX,   RX,  W10, RSYN, RSYN, SSYN, RSYN, RSYN},
	{ RSYN,   RX,   RX,  W10, RSYN, RSYN, RSYN, SSYN, RSYN},
	{ RSYN,   RX,   RX,  W10, RSYN, RSYN, RSYN, RSYN, SSYN}
};

std::vector<std::vector<uint8_t>> RipsDat::MULT_RX_1 = {
	{	TX1,	TX1,	W10,	RSYN,	RX,	W10,	SSYN,	RSYN,	RSYN,	RSYN	},
	{	TX2,	RX,	W10,	RSYN,	TX1,	W10,	RSYN,	SSYN,	RSYN,	RSYN	},
	{	RX,	TX2,	W10,	RSYN,	TX2,	W10,	RSYN,	RSYN,	SSYN,	RSYN	},
	{	RX,	RX,	W10,	SSYN,	RX,	W10,	RSYN,	RSYN,	RSYN,	SSYN	}
};

std::vector<std::vector<uint8_t>> RipsDat::SCHEDULER_AND_RSSI_LOC_TESTER = {
	{	RSYN,	TX1,	RX,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	NTRX,	NTRX,	SSYN,	RSYN,	RSYN,	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	RSYN	},
	{	RSYN,	RX,	TX1,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	NTRX,	NTRX,	RSYN,	SSYN,	RSYN,	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	RSYN	},
	{	RSYN,	RX,	TX2,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	SSYN,	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	RSYN	},
	{	RSYN,	TX2,	RX,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	TX1,	RX,	RSYN,	RSYN,	RSYN,	RSYN,	NTRX,	NTRX,	SSYN,	RSYN,	RSYN	},
	{	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RX,	TX1,	RSYN,	RSYN,	RSYN,	RSYN,	NTRX,	NTRX,	RSYN,	SSYN,	RSYN	},
	{	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	RSYN,	RSYN,	RSYN,	RX,	TX2,	RSYN,	RSYN,	RSYN,	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	SSYN	},
	{	RSYN,	NTRX,	NTRX,	SSYN,	RSYN,	RSYN,	RSYN,	RSYN,	TX2,	RX,	RSYN,	RSYN,	RSYN,	RSYN,	RX,	TX1,	RSYN,	RSYN,	RSYN	},
	{	RSYN,	NTRX,	NTRX,	RSYN,	SSYN,	RSYN,	RSYN,	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	RSYN,	RSYN,	TX1,	RX,	RSYN,	RSYN,	RSYN	},
	{	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	SSYN,	RSYN,	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	RSYN,	RSYN,	TX2,	RX,	RSYN,	RSYN,	RSYN	},
	{	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	RSYN,	SSYN,	RSYN,	NTRX,	NTRX,	RSYN,	RSYN,	RSYN,	RSYN,	RX,	TX2,	RSYN,	RSYN,	RSYN	},
	{	SSYN,	RX,	RX,	RSYN,	RSYN,	RSYN,	RSYN,	SSYN,	RX,	RX,	RSYN,	RSYN,	RSYN,	SSYN,	RX,	RX,	RSYN,	RSYN,	RSYN	}
};

std::vector<std::pair<const char *, const std::vector<std::vector<uint8_t>>&>> RipsDat::NAMES = {
	{"FOUR_MOTE", FOUR_MOTE},
	{"SIX_MOTE", SIX_MOTE},
	{"PHASEMAP_TEST_4", PHASEMAP_TEST_4},
	{"PHASEMAP_TEST_5", PHASEMAP_TEST_5},
	{"PHASEMAP_TEST_6", PHASEMAP_TEST_6},
	{"PHASEMAP_TEST_12", PHASEMAP_TEST_12},
	{"PHASEMAP_TEST_18", PHASEMAP_TEST_18},
	{"LOC_TEST_9_GRID", LOC_TEST_9_GRID},
	{"LOC_MULT_TX", LOC_MULT_TX},
	{"LOC_4TX_4ANCHORRX", LOC_4TX_4ANCHORRX},
	{"LOC_4TX_NOANCHORRX", LOC_4TX_NOANCHORRX},
	{"PHASEMAP_TEST_8", PHASEMAP_TEST_8},
	{"MULT_RX_1", MULT_RX_1},
	{"SCHEDULER_AND_RSSI_LOC_TESTER", SCHEDULER_AND_RSSI_LOC_TESTER}
};

const std::vector<std::vector<uint8_t>> &RipsDat::get_schedule(const char *schedule) {
	for (uint i = 0; i < NAMES.size(); i++) {
		if (strcmp(schedule, NAMES[i].first) == 0)
			return NAMES[i].second;
	}

	std::string msg = "Unknown schedule: ";
	msg += schedule;
	throw std::invalid_argument(msg);
}

RipsDat::RipsDat(const std::vector<std::vector<uint8_t>> &schedule) : in(bind(&RipsDat::decode, this)), schedule(&schedule) {
	analize_schedule();
}

RipsDat::RipsDat(const char *schedule) : in(bind(&RipsDat::decode, this)), schedule(&get_schedule(schedule)) {
	analize_schedule();
}

RipsDat::RipsDat() : in(bind(&RipsDat::search, this)), schedule(NULL) {
	for (uint i = 0; i < NAMES.size(); i++)
		possibilities.push_back(i);
}

void RipsDat::analize_schedule() {
	assert(schedule != NULL);

	if (schedule->size() < 4)
		throw std::invalid_argument("RipsDat schedule: not enough nodes");

	node_count = schedule->size();
	rx_indices.resize(node_count);

	slot_count = (*schedule)[0].size();
	for (uint i = 1; i < node_count; i++)
		if ((*schedule)[i].size() != slot_count)
			throw std::invalid_argument("RipsDat schedule: non-uniform slots");

	for (uint j = 0; j < slot_count; j++) {
		Packet packet;

		packet.frame = 0;
		packet.slot = j;
		packet.subframe = get_subframe(packet.slot);
		packet.sender1 = 0;
		packet.sender2 = 0;

		for (uint i = 0; i < node_count; i++) {
			uint8_t s = (*schedule)[i][j];
			if (s == TX1)
				packet.sender1 += 1;
			else if (s == TX2)
				packet.sender2 += 1;
		}

		if (packet.sender1 == 0 && packet.sender2 == 0)
			continue;
		if (packet.sender1 != 1 || packet.sender2 != 1)
			throw std::invalid_argument("RipsDat schedule: incorrect number of TXs");

		for (uint i = 0; i < node_count; i++) {
			uint8_t s = (*schedule)[i][j];
			if (s == TX1)
				packet.sender1 = i + 1;
			else if (s == TX2)
				packet.sender2 = i + 1;
			else if (s == RX)
				rx_indices[i].push_back(history.size());
		}

		history.push_back(packet);
	}
}

float RipsDat::get_subframe(uint slot) {
	return ((float) slot) / slot_count;
}

void RipsDat::decode(const RipsMsg::Packet &rips) {
	if (rips.nodeid < 1 || rips.nodeid > node_count)
		std::cerr << "RipsDat schedule mismatch: node id\n";
	else if (rips.slot >= slot_count)
		std::cerr << "RipsDat schedule mismatch: slot number\n";
	else if (rx_indices[rips.nodeid - 1].size() != rips.measurements.size())
		std::cerr << "RipsDat schedule mismatch: measurement count\n";
	else {
		uint n = rips.nodeid - 1;
		uint s = (rips.slot + slot_count - 1) % slot_count;	// back up one (different slot logic in mote)

		if ((*schedule)[n][s] != SSYN)
			std::cerr << "RipsDat schedule mismatch: send sync slot\n";
		else {
			// send out old packets
			do {
				if (history[current_index].slot == current_slot) {
					Packet &packet = history[current_index];
					if (packet.measurements.size() != 0)
						out.send(packet);

					packet.frame += 1;
					packet.measurements.clear();

					current_index = (current_index + 1) % history.size();
				}

				current_slot = (current_slot + 1) % slot_count;
			} while (current_slot != s);

			for (uint i = 0; i < rips.measurements.size(); i++) {
				Packet &packet = history[rx_indices[n][i]];

				for (Measurement m : packet.measurements)
					assert(m.nodeid != rips.nodeid);

				Measurement m;
				m.nodeid = rips.nodeid;
				m.period = rips.measurements[i].period;
				m.phase = rips.measurements[i].phase;
				m.rssi1 = rips.measurements[i].rssi1;
				m.rssi2 = rips.measurements[i].rssi2;
				packet.measurements.push_back(m);
			}
		}
	}
}

void RipsDat::search(const RipsMsg::Packet &rips) {
	if (schedule != NULL) {
		decode(rips);
		return;
	}

	backlog.push_back(rips);

	std::vector<uint>::iterator pos = possibilities.begin();
	while (pos != possibilities.end()) {
		if (contradicts(rips, NAMES[*pos].second))
			pos = possibilities.erase(pos);
		else
			pos++;
	}

	if (possibilities.size() < 0)
		throw std::runtime_error("RipsDat input contradicts all schedules");
	else if (possibilities.size() == 1) {
		uint n = possibilities.front();
		std::cerr << "RipsDat detecting " << NAMES[n].first << " schedule\n";

		schedule = &(NAMES[n].second);
		analize_schedule();

		for (uint i = 0; i < backlog.size(); i++)
			decode(backlog[i]);

		backlog.clear();
	}
	else if (backlog.size() >= 100)
		throw std::runtime_error("RipsDat could not match schedule");
}

bool RipsDat::contradicts(const RipsMsg::Packet &rips, const std::vector<std::vector<uint8_t>> &schedule) {
	uint node_count = schedule.size();
	if (node_count == 0 || rips.nodeid < 1 || rips.nodeid > node_count)
		return true;

	uint slot_count = schedule[0].size();
	if (rips.slot < 0 || rips.slot >= slot_count)
		return true;

	uint n = rips.nodeid - 1;
	uint s = (rips.slot + slot_count - 1) % slot_count;
	if (schedule[n].size() != slot_count || schedule[n][s] != SSYN)
		return true;

	return false;
}

std::ostream& operator <<(std::ostream& stream, const RipsDat::Packet &packet) {
	stream << packet.sender1 << ", " << packet.sender2;
	for (RipsDat::Measurement mnt : packet.measurements)
		stream << ",\t" << mnt.nodeid << ", " << mnt.phase << ", " << mnt.period;
	return stream;
}

const RipsDat::Measurement *RipsDat::Packet::get_measurement(uint nodeid) const {
	std::vector<Measurement>::const_iterator iter = measurements.begin();
	while (iter != measurements.end()) {
		if (iter->nodeid == nodeid)
			return &*iter;

		iter++;
	}
	return NULL;
}

// ------- RipsDat2

RipsDat2::RipsDat2() : in(bind(&RipsDat2::decode, this)) {
}

void RipsDat2::decode(const RipsDat::Packet &pkt) {
	if (pkt.slot >= slots.size()) {
		slots.resize(pkt.slot + 1);
	}

	assert(pkt.slot < slots.size());
	slots[pkt.slot].decode(pkt, out);
}

RipsDat2::Slot::Slot() : history_head(0), full(false) {
}

void RipsDat2::Slot::decode(const RipsDat::Packet &pkt, Output<Packet> &out) {
	for (RipsDat::Measurement mnt : pkt.measurements) {
		if (mnt.period <= 0)
			continue;

		history[history_head] = mnt.period;
		if (++history_head >= HISTORY_SIZE) {
			history_head = 0;
			full = true;
		}
	}

	if (!full)
		return;

	int temp[HISTORY_SIZE];
	std::memcpy(temp, history, sizeof(int) * HISTORY_SIZE);

	std::sort(temp, temp + HISTORY_SIZE);

	int sum = 0;
	for (int i = 0; i < AVERAGE_SIZE; i++)
		sum += temp[(HISTORY_SIZE - AVERAGE_SIZE) / 2 + i];

	float period = sum * (1.0 / AVERAGE_SIZE);

	RipsDat2::Packet packet;
	packet.frame = pkt.frame;
	packet.slot = pkt.slot;
	packet.subframe = pkt.subframe;
	packet.sender1 = pkt.sender1;
	packet.sender2 = pkt.sender2;
	packet.period = period;

	int period_min = std::round(period * (1.0f - 0.5f / PERIOD_FRAC));
	int period_max = std::round(period * (1.0f + 0.5f / PERIOD_FRAC));

	for (const RipsDat::Measurement &mnt : pkt.measurements) {
		if (mnt.period <= 0)
			continue;

		if (period_min <= mnt.period && mnt.period <= period_max) {
			RipsDat2::Measurement measurement;
			measurement.nodeid = mnt.nodeid;
			measurement.phase = 1.0 * mnt.phase / mnt.period;
			assert(0.0f <= measurement.phase && measurement.phase < 1.0f);

			packet.measurements.push_back(measurement);
		}
	}

	out.send(packet);
}

std::ostream& operator <<(std::ostream& stream, const RipsDat2::Packet &packet) {
	stream.precision(2);
	stream.setf(std::ios::fixed, std::ios::floatfield);

	stream << packet.sender1 << ", " << packet.sender2 << ", " << packet.period;
	for (RipsDat2::Measurement mnt : packet.measurements)
		stream << ",\t" << mnt.nodeid << ", " << mnt.phase;

	return stream;
}

const RipsDat2::Measurement *RipsDat2::Packet::get_measurement(uint nodeid) const {
	std::vector<Measurement>::const_iterator iter = measurements.begin();
	while (iter != measurements.end()) {
		if (iter->nodeid == nodeid)
			return &*iter;

		iter++;
	}
	return NULL;
}

// ------- RipsQuad

RipsQuad::RipsQuad(uint sender1, uint sender2, uint receiver1, uint receiver2)
	: in(bind(&RipsQuad::decode, this)),
	sender1(sender1), sender2(sender2), receiver1(receiver1), receiver2(receiver2)
{
}

void RipsQuad::decode(const RipsDat2::Packet &pkt) {
	if (pkt.sender1 != sender1 || pkt.sender2 != sender2)
		return;

	const RipsDat2::Measurement *mnt1 = pkt.get_measurement(receiver1);
	if (mnt1 == NULL || mnt1->phase == 0)
		return;

	const RipsDat2::Measurement *mnt2 = pkt.get_measurement(receiver2);
	if (mnt2 == NULL || mnt2->phase == 0)
		return;

	float relphase = std::fmod(mnt1->phase - mnt2->phase + 2.0f, 1.0);
	assert(0.0f <= relphase && relphase < 1.0f);

	Packet packet;
	packet.frame = pkt.frame;
	packet.subframe = pkt.subframe;
	packet.relphase = relphase;
	out.send(packet);
}

std::ostream& operator <<(std::ostream& stream, const RipsQuad::Packet &packet) {
	stream.precision(2);
	stream.setf(std::ios::fixed, std::ios::floatfield);

	stream << ((double) packet.frame + packet.subframe) << ", " << packet.relphase;
	return stream;
}
