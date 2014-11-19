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

#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <poll.h>
#include <cstring>
#include <vector>
#include <memory>


SerialBase::SerialBase(const char *devicename, int baudrate)
	: Consumer<std::vector<unsigned char>>(devicename), serial_fd(-1) {
	try {
		serial_fd = open(devicename, O_RDWR | O_NOCTTY);
		if (serial_fd < 0)
			throw std::runtime_error("Could not open " + get_name() + ": " + std::strerror(errno));

		if (baudrate > 0) {
			struct termios newtio;
			memset(&newtio, 0, sizeof(newtio));
			newtio.c_cflag = CS8 | CLOCAL | CREAD;
			newtio.c_iflag = IGNPAR | IGNBRK;
			newtio.c_oflag = 0;
			cfsetspeed(&newtio, baudrate);

			if (tcflush(serial_fd, TCIFLUSH) < 0 || tcsetattr(serial_fd, TCSANOW, &newtio) < 0)
				throw std::runtime_error("Could not set baudrate for " + get_name() + ": " + std::strerror(errno));
		}

		reader_thread = std::unique_ptr<std::thread>(new std::thread(&SerialBase::pump, this));
		std::cerr << "Opened device " << devicename << " with baudrate " << baudrate << std::endl;
	}
	catch(const std::exception &e) {
		if (serial_fd >= 0) {
			close(serial_fd);
			serial_fd = -1;
		}

		throw;
	}
}

SerialBase::~SerialBase() {
	reader_exit = true;
	if (reader_thread != NULL)
		reader_thread->join();

	close(serial_fd);

	std::cerr << "Closed device " << get_name() << std::endl;
}

void SerialBase::work(const std::vector<unsigned char> &packet) {
	std::vector<unsigned char> encoded;

	encoded.push_back(HDLC_FLG);
	for (unsigned char c : packet) {
		if (c == HDLC_FLG || c == HDLC_ESC) {
			encoded.push_back(HDLC_ESC);
			c ^= HDLC_XOR;
		}
		encoded.push_back(c);
	}
	encoded.push_back(HDLC_FLG);

	std::lock_guard<std::mutex> lock(write_mutex);

	int sent = 0;
	do {
		int n = write(serial_fd, encoded.data() + sent, encoded.size() - sent);
		if (n < 0)
			throw std::runtime_error(get_name() + " write failed: " + std::strerror(errno));
		else
			sent += n;
	} while (sent < encoded.size());
}

void SerialBase::pump() {
	struct pollfd fds[1];
	fds[0].fd = serial_fd;
	fds[0].events = POLLIN | POLLPRI;

	while (!reader_exit) {
		int n = poll(fds, 1, 1000);	// 100 ms timeout
		if (n < 0)
			throw std::runtime_error(get_name() + " poll failed: " + std::strerror(errno));
		if (reader_exit)
			return;

		std::cerr << std::to_string(n) << std::endl;
	}
}
