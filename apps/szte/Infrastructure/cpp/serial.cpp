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

#include "serial.hpp"

// ------- SerialFrm

SerialFrm::SerialFrm()
	: sub_in(bind(&SerialFrm::decode, this)), in(bind(&SerialFrm::encode, this)) {
}

void SerialFrm::decode(const std::vector<unsigned char> &packet) {
	for (unsigned char c : packet) {
		if (c == HDLC_FLAG) {
			if (synchronized && decoded.size() > 0) {
				if (decoded.size() < 2)
					std::cerr << "Dropping packet, length too short\n";
				else {
					uint16_t crc = 0;
					for (unsigned int i = 0; i < decoded.size() - 2; i++)
						crc = calc_crc(crc, decoded[i]);

					uint16_t d = static_cast<uint16_t>(decoded[decoded.size() - 1]) << 8;
					d += static_cast<uint16_t>(decoded[decoded.size() - 2]);

					if (crc != d)
						std::cerr << "Dropping packet, incorrect CRC\n";
					else {
						decoded.resize(decoded.size() - 2);
						out.send(decoded);
					}
				}

				decoded.clear();
			}
			else
				synchronized = true;

			escaped = false;
		}
		else if (!synchronized)
			;
		else if (c == HDLC_ESCAPE)
			escaped = true;
		else {
			if (decoded.size() >= FRAME_MAXLEN) {
				std::cerr << "Packet too long, resynchronizing\n";

				decoded.clear();
				synchronized = false;
			}
			else {
				if (escaped) {
					c ^= HDLC_XOR;
					escaped = false;
				}

				decoded.push_back(c);
			}
		}
	}
}

void SerialFrm::encode(const std::vector<unsigned char> &packet) {
	std::vector<unsigned char> encoded;
	encoded.reserve(packet.size() + 50);

	encoded.push_back(HDLC_FLAG);

	uint16_t crc = 0;

	for (unsigned char data : packet) {
		crc = calc_crc(crc, data);
		encode_byte(data, encoded);
	}

	encode_byte(static_cast<unsigned char>(crc), encoded);
	encode_byte(static_cast<unsigned char>(crc >> 8), encoded);

	encoded.push_back(HDLC_FLAG);

	sub_out.send(encoded);
}

void SerialFrm::encode_byte(unsigned char data, std::vector<unsigned char> &packet) {
	if (data == HDLC_FLAG || data == HDLC_ESCAPE) {
		packet.push_back(HDLC_ESCAPE);
		data ^= HDLC_XOR;
	}
	packet.push_back(data);
}

uint16_t SerialFrm::calc_crc(uint16_t crc, unsigned char data) {
      crc ^= static_cast<uint16_t>(data) << 8;

      for (int i = 0; i < 8; i++) {
	if (static_cast<int16_t>(crc) < 0)
	  crc = (crc << 1) ^ 0x1021;
	else
	  crc = crc << 1;
      }

      return crc;
}

// ------- SerialAck

SerialAck::SerialAck()
	: sub_in(bind(&SerialAck::decode, this)), in(bind(&SerialAck::encode, this)) {
}

void SerialAck::decode(const std::vector<unsigned char> &packet) {
	if (packet.size() >= 1 && packet[0] == SERIAL_PROTO_PACKET_NOACK) {
		std::vector<unsigned char> decoded(packet.begin() + 1, packet.end());
		out.send(decoded);
	}
	else if (packet.size() >= 2 && packet[0] == SERIAL_PROTO_PACKET_ACK) {
		std::vector<unsigned char> decoded(packet.begin() + 2, packet.end());
		out.send(decoded);

		decoded.clear();
		decoded.push_back(SERIAL_PROTO_ACK);
		decoded.push_back(packet[1]);
		sub_out.send(decoded);
	}
	else if (packet.size() == 2 && packet[0] == SERIAL_PROTO_ACK)
		;  // TODO: check ACKs
	else
		std::cerr << "Dropping packet, invalid protocol\n";
}

void SerialAck::encode(const std::vector<unsigned char> &packet) {
	std::vector<unsigned char> encoded;
	encoded.reserve(packet.size() + 1);

	// TODO: use PROTO_PACKET_ACK
	encoded.push_back(SERIAL_PROTO_PACKET_NOACK);
	encoded.insert(encoded.end(), packet.begin(), packet.end());
	sub_out.send(encoded);
}

// ------- Serial

Serial::Serial(const char *devicename, int baudrate) : in(proto.in), out(proto.out), device(devicename, baudrate) {
	connect(proto.sub_out, framer.in);
	connect(framer.sub_out, device.in);

	connect(device.out, framer.sub_in);
	connect(framer.out, proto.sub_in);
}

Serial::~Serial() {
	disconnect(proto.sub_out, framer.in);
	disconnect(framer.sub_out, device.in);

	disconnect(device.out, framer.sub_in);
	disconnect(framer.out, proto.sub_in);
}
