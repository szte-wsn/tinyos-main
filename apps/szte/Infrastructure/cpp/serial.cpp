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

SerialBase::SerialBase(const char *devicename, int baudrate)
	: in(bind(&SerialBase::work, this)), devicename(devicename) {
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
		reader_thread = std::unique_ptr<std::thread>(new std::thread(&SerialBase::pump, this));
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

SerialBase::~SerialBase() {
	unsigned char data = 0;
	write(pipe_fds[1], &data, 1);

	if (reader_thread != NULL)
		reader_thread->join();

	close(serial_fd);
	close(pipe_fds[0]);
	close(pipe_fds[1]);

	std::cerr << "Closed " << devicename << std::endl;
}

void SerialBase::work(const std::vector<unsigned char> &packet) {
	std::vector<unsigned char> encoded;

	encoded.push_back(HDLC_FLAG);
	for (unsigned char c : packet) {
		if (c == HDLC_FLAG || c == HDLC_ESCAPE) {
			encoded.push_back(HDLC_ESCAPE);
			c ^= HDLC_XOR;
		}
		encoded.push_back(c);
	}
	encoded.push_back(HDLC_FLAG);

	std::lock_guard<std::mutex> lock(write_mutex);

	int sent = 0;
	do {
		int n = write(serial_fd, encoded.data() + sent, encoded.size() - sent);
		if (n < 0)
			error("Write", errno);
		else
			sent += n;
	} while (sent < encoded.size());
}

void SerialBase::pump() {
	struct pollfd fds[2];
	fds[0].fd = pipe_fds[0];
	fds[0].events = POLLIN | POLLPRI;
	fds[1].fd = serial_fd;
	fds[1].events = POLLIN | POLLPRI;

	std::vector<unsigned char> packet;
	packet.reserve(READ_MAXLEN);
	bool synchronize = true;
	bool escaped;

	for(;;) {
		int a = poll(fds, 2, -1);
		if (a < 0)
			error("Poll", errno);

		if ((fds[0].revents & (POLLIN | POLLPRI)) != 0)
			return;
		else if ((fds[1].revents & (POLLIN | POLLPRI)) != 0) {
			ssize_t n = read(serial_fd, read_buffer, READ_BUFFER);
			if (n < 0)
				error("Read", errno);
			else if (n == 0)	// TODO: implement auto reconnect
				throw std::runtime_error("Disconnected " + devicename);

			for (int i = 0; i < n; ++i) {
				unsigned char c = read_buffer[i];

				if (c == HDLC_FLAG) {
					if (!synchronize && packet.size() > 0) {
						out.send(packet);
						packet.clear();
					}

					synchronize = false;
					escaped = false;
				}
				else if (synchronize)
					;
				else if (c == HDLC_ESCAPE)
					escaped = true;
				else {
					if (packet.size() >= READ_MAXLEN) {
						std::cerr << "Synchronizing " << devicename << std::endl;
						synchronize = true;
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

	}
}

void SerialBase::error(const char *msg, int err) {
	throw std::runtime_error(std::string(msg) + " failed for " + devicename + ": " + std::strerror(err));
}
