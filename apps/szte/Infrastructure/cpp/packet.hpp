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

#ifndef __PACKET_HPP__
#define __PACKET_HPP__

#include "block.hpp"
#include <vector>

uint16_t read_uint16(std::vector<unsigned char>::const_iterator pos);
uint32_t read_uint32(std::vector<unsigned char>::const_iterator pos);

inline uint8_t read_uint8(std::vector<unsigned char>::const_iterator pos) {
	return *pos;
}

inline int8_t read_int8(std::vector<unsigned char>::const_iterator pos) {
	return read_uint8(pos);
}

inline int16_t read_int16(std::vector<unsigned char>::const_iterator pos) {
	return read_uint16(pos);
}

inline int32_t read_int32(std::vector<unsigned char>::const_iterator pos) {
	return read_uint32(pos);
}

class SerialTos : public Block {
public:
	struct Packet {
		uint16_t dest;
		uint16_t src;
		uint8_t group;
		uint8_t type;
		std::vector<unsigned char> payload;
	};

	Input<std::vector<unsigned char>> sub_in;
	Output<std::vector<unsigned char>> sub_out;

	Input<Packet> in;
	Output<Packet> out;

	SerialTos(bool ignore = true);

private:
	bool ignore;

	enum {
		TOS_SERIAL_ACTIVE_MESSAGE_ID = 0,
	};

	void decode(const std::vector<unsigned char> &packet);
	void encode(const Packet &packet);

	void error(const char *what, const std::vector<unsigned char> &packet);
};

std::ostream& operator <<(std::ostream& stream, const SerialTos::Packet &packet);

struct SyncMsg {
	struct Measurement {
		uint8_t freq;
		uint8_t phase;
	};

	uint16_t sender;
	uint8_t frame;
	std::vector<Measurement> measurements;
};

std::ostream& operator <<(std::ostream& stream, const SyncMsg &msg);

class SyncMsgParser : public Block {
public:
	Input<std::vector<unsigned char>> in;
	Output<SyncMsg> out;

	SyncMsgParser();

private:
	void decode(const std::vector<unsigned char> &packet);
};

#endif//__PACKET_HPP__
