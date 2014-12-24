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

#ifndef __SERIAL_HPP__
#define __SERIAL_HPP__

#include "block.hpp"
#include "compat.hpp"

class SerialFrm : public Block {
public:
	Input<std::vector<unsigned char>> sub_in;
	Output<std::vector<unsigned char>> sub_out;

	Input<std::vector<unsigned char>> in;
	Output<std::vector<unsigned char>> out;

	SerialFrm();

private:
	enum {
		HDLC_FLAG = 126,
		HDLC_ESCAPE = 125,
		HDLC_XOR = 32,
		FRAME_MAXLEN = 255,
	};

	bool synchronized = false, escaped;
	std::vector<unsigned char> decoded;
	void decode(const std::vector<unsigned char> &packet);

	static void encode_byte(unsigned char data, std::vector<unsigned char> &packet);
	static uint16_t calc_crc(uint16_t crc, unsigned char data);
	void encode(const std::vector<unsigned char> &packet);
};

class SerialAck : public Block {
public:
	Input<std::vector<unsigned char>> sub_in;
	Output<std::vector<unsigned char>> sub_out;

	Input<std::vector<unsigned char>> in;
	Output<std::vector<unsigned char>> out;

	SerialAck();

private:
	enum {
		SERIAL_PROTO_ACK = 67,
		SERIAL_PROTO_PACKET_ACK = 68,
		SERIAL_PROTO_PACKET_NOACK = 69,
	};

	void decode(const std::vector<unsigned char> &packet);
	void encode(const std::vector<unsigned char> &packet);
};

class Serial : public Block {
public:
	Input<std::vector<unsigned char>> &in;
	Output<std::vector<unsigned char>> &out;

	Serial(const char *devicename, int baudrate);
	~Serial();

private:
	SerialDev device;
	SerialFrm framer;
	SerialAck proto;
};

#endif//__SERIAL_HPP__
