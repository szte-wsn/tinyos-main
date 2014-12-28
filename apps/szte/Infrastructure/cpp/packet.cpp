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

RipsMsg::RipsMsg() : sub_in(bind(&RipsMsg::decode, this)) {
}

void RipsMsg::decode(const TosMsg::Packet &tos) {
	if (tos.type != 0x06)
		return;

	if (tos.payload.size() % 2 != 1)
		runtime_error("Invalid RipsMsg length", tos);

	Packet packet;
	packet.moteid = tos.src;
	packet.frame = read_uint8(tos.payload.begin());
	for (unsigned int i = 1; i < tos.payload.size(); i += 2) {
		Measurement mnt;
		mnt.freq = read_uint8(tos.payload.begin() + i);
		mnt.phase = read_uint8(tos.payload.begin() + i + 1);
		packet.measurements.push_back(mnt);
	}

	out.send(packet);
}

std::ostream& operator <<(std::ostream& stream, const RipsMsg::Packet &packet) {
	stream << std::dec;
	stream << "mid=" << static_cast<int>(packet.moteid);
	stream << " frm=" << static_cast<int>(packet.frame);
	stream << " [";
	for (RipsMsg::Measurement mnt : packet.measurements)
		stream << " " << static_cast<int>(mnt.phase) << "/" << static_cast<int>(mnt.freq);
	stream << " ]";
	return stream;
}
