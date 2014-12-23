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
#include <cstring>
#include <vector>
#include <memory>

#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <poll.h>

SerialDev::SerialDev(const char *devicename, int baudrate)
	: in(bind(&SerialDev::work, this)), devicename(devicename) {

	serial_fd = -1;
	pipe_fds[0] = -1;
	pipe_fds[1] = -1;

	try {
		int a = pipe2(pipe_fds, O_NONBLOCK);
		if (a < 0)
			error("Creating pipe", errno);

		serial_fd = open(devicename, O_RDWR | O_NOCTTY);
		if (serial_fd < 0)
			error("Open", errno);

		struct termios newtio;
		memset(&newtio, 0, sizeof(newtio));
		newtio.c_cflag = CS8 | CLOCAL | CREAD;
		newtio.c_iflag = IGNPAR | IGNBRK;
		newtio.c_oflag = 0;
		cfsetspeed(&newtio, baudrate);

		if (tcflush(serial_fd, TCIFLUSH) < 0 || tcsetattr(serial_fd, TCSANOW, &newtio) < 0)
			error("Set baudrate", errno);

		std::cerr << "Opened " << devicename << " with baudrate " << baudrate << std::endl;
		reader_thread = std::unique_ptr<std::thread>(new std::thread(&SerialDev::pump, this));
	}
	catch(const std::exception &e) {
		if (serial_fd >= 0)
			close(serial_fd);
		if (pipe_fds[0] >= 0)
			close(pipe_fds[0]);
		if (pipe_fds[1] >= 0)
			close(pipe_fds[1]);

		throw;
	}
}

SerialDev::~SerialDev() {
	unsigned char data = 0;
	ssize_t ignore = write(pipe_fds[1], &data, 1);
	(void) ignore;

	if (reader_thread != NULL)
		reader_thread->join();

	close(serial_fd);
	close(pipe_fds[0]);
	close(pipe_fds[1]);

	std::cerr << "Closed " << devicename << std::endl;
}

void SerialDev::work(const std::vector<unsigned char> &packet) {
	std::lock_guard<std::mutex> lock(write_mutex);

	unsigned int sent = 0;
	do {
		int n = write(serial_fd, packet.data() + sent, packet.size() - sent);
		if (n < 0)
			error("Write", errno);
		else
			sent += n;
	} while (sent < packet.size());
}

void SerialDev::pump() {
	struct pollfd fds[2];
	fds[0].fd = pipe_fds[0];
	fds[0].events = POLLIN | POLLPRI;
	fds[1].fd = serial_fd;
	fds[1].events = POLLIN | POLLPRI;

	std::vector<unsigned char> packet;

	for(;;) {
		int a = poll(fds, 2, -1);
		if (a < 0)
			error("Poll", errno);

		if ((fds[0].revents & (POLLIN | POLLPRI)) != 0)
			return;
		else if ((fds[1].revents & (POLLIN | POLLPRI)) != 0) {

			packet.resize(READ_BUFFER);
			ssize_t n = read(serial_fd, &packet[0], READ_BUFFER);
			if (n < 0 || n > READ_BUFFER)
				error("Read", errno);
			else if (n == 0)	// TODO: implement auto reconnect
				throw std::runtime_error("Disconnected " + devicename);

			packet.resize(n);
			out.send(packet);
		}

	}
}

void SerialDev::error(const char *msg, int err) {
	throw std::runtime_error(std::string(msg) + " failed for " + devicename + ": " + std::strerror(err));
}

SerialFrm::SerialFrm()
	: dev_in(bind(&SerialFrm::recv_frame, this)), tos_in(bind(&SerialFrm::send_packet, this)) {
}

void SerialFrm::recv_frame(const std::vector<unsigned char> &encoded) {
	for (unsigned char c : encoded) {
		if (c == HDLC_FLAG) {
			if (synchronized && packet.size() > 0) {
				if (packet.size() < 4)
					std::cerr << "Dropping packet, length too short\n";
				else {
					uint16_t crc = 0;
					for (unsigned int i = 0; i < packet.size() - 2; i++)
						crc = calc_crc(crc, packet[i]);

					uint16_t d = static_cast<uint16_t>(packet[packet.size() - 1]) << 8;
					d += static_cast<uint16_t>(packet[packet.size() - 2]);

					if (crc != d)
						std::cerr << "Dropping packet, incorrect CRC\n";
					else {
						unsigned char address = packet[0];
						unsigned char control = packet[1];
						packet.resize(packet.size() - 2);
						packet.erase(packet.begin(), packet.begin() + 2);

						recv_packet(address, control, packet);
					}
				}

				packet.clear();
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
			if (packet.size() >= FRAME_MAXLEN) {
				std::cerr << "Packet too long, resynchronizing\n";

				packet.clear();
				synchronized = false;
			}
			else {
				if (escaped) {
					c ^= HDLC_XOR;
					escaped = false;
				}

				packet.push_back(c);
			}
		}
	}
}

void SerialFrm::recv_packet(unsigned char address, unsigned char control, const std::vector<unsigned char> &packet) {
	if (address == PROTO_PACKET_ACK || address == PROTO_PACKET_NOACK) {
		tos_out.send(packet);

		if (address == PROTO_PACKET_ACK) {
			std::vector<unsigned char> ack;
			send_frame(PROTO_ACK, control, ack);
		}
	}
	else if (address == PROTO_ACK && packet.size() == 0) // TODO: check ACKs
		;
	else
		std::cerr << "Dropping packet, invalid protocol\n";
}

void SerialFrm::send_packet(const std::vector<unsigned char> &packet) {
	// TODO: use PROTO_PACKET_ACK
	send_frame(PROTO_PACKET_NOACK, 0, packet);
}

void SerialFrm::send_frame(uint8_t address, uint8_t control, const std::vector<unsigned char> &packet) {
	std::vector<unsigned char> encoded;
	encoded.reserve(packet.size() + 50);

	encoded.push_back(HDLC_FLAG);

	uint16_t crc = calc_crc(0, address);
	encode_byte(address, encoded);

	crc = calc_crc(crc, control);
	encode_byte(control, encoded);

	for (unsigned char data : packet) {
		crc = calc_crc(crc, data);
		encode_byte(data, encoded);
	}

	encoded.push_back(HDLC_FLAG);

	dev_out.send(encoded);
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

Serial::Serial(const char *devicename, int baudrate) : in(framer.tos_in), out(framer.tos_out), device(devicename, baudrate) {
	connect(framer.dev_out, device.in);
	connect(device.out, framer.dev_in);
}

Serial::~Serial() {
	disconnect(framer.dev_out, device.in);
	disconnect(device.out, framer.dev_in);
}
