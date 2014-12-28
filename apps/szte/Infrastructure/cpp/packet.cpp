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
#include <sstream>

// ------- SerialTos

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

SerialTos::SerialTos(bool ignore)
	: sub_in(bind(&SerialTos::decode, this)),
	in(bind(&SerialTos::encode, this)), ignore(ignore) {
}

void SerialTos::decode(const std::vector<unsigned char> &raw) {
	if (raw[0] != 0) {
		if (ignore)
			return;
		else
			error("Invalid TOS packet type", raw);
	}

	uint8_t len = read_uint8(raw.begin() + 5);
	if (static_cast<unsigned int>(len) + 8 != raw.size())
		error("Invalid TOS packet length", raw);

	Packet packet;
	packet.dest = read_uint16(raw.begin() + 1);
	packet.src = read_uint16(raw.begin() + 3);
	packet.group = read_uint8(raw.begin() + 6);
	packet.type = read_uint8(raw.begin() + 7);
	packet.payload.insert(packet.payload.begin(), raw.begin() + 8, raw.end());

	out.send(packet);
}

void SerialTos::error(const char *what, const std::vector<unsigned char> &packet) {
	std::ostringstream buffer;
	buffer << what << " " << packet;
	throw std::runtime_error(buffer.str());
}

void SerialTos::encode(const SerialTos::Packet &packet) {
}

std::ostream& operator <<(std::ostream& stream, const SerialTos::Packet &packet) {
	stream << "dst=" << static_cast<int>(packet.dest);
	stream << " src=" << static_cast<int>(packet.src);
	stream << " grp=" << static_cast<int>(packet.group);
	stream << " typ=" << static_cast<int>(packet.type);
	stream << " " << packet.payload;
	return stream;
}

// ------- SyncMsg

SyncMsgParser::SyncMsgParser() : in(bind(&SyncMsgParser::decode, this)) {
}

void SyncMsgParser::decode(const std::vector<unsigned char> &packet) {

}

