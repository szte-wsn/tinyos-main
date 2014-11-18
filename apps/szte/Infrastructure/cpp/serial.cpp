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

#include <cstring>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <vector>

#include "serial.hpp"

SerialBase::SerialBase(const char *devicename, int baudrate)
	: Consumer<std::vector<unsigned char>>(devicename),
	devicename(devicename) {

	read_fd = open(devicename, O_RDONLY | O_NOCTTY);
	if (read_fd < 0)
		throw std::runtime_error("could not open " + this->devicename);

	write_fd = open(devicename, O_WRONLY | O_NOCTTY);
	if (write_fd < 0) {
		close(read_fd);
		throw std::runtime_error("could not open " + this->devicename);
	}

	struct termios newtio;
	memset(&newtio, 0, sizeof(newtio));
	newtio.c_cflag = CS8 | CLOCAL | CREAD;
	newtio.c_iflag = IGNPAR | IGNBRK;
	newtio.c_oflag = 0;
	cfsetspeed(&newtio, baudrate);

	if (tcflush(read_fd, TCIFLUSH) < 0 || tcsetattr(read_fd, TCSANOW, &newtio) < 0
		|| tcflush(write_fd, TCIFLUSH) < 0 || tcsetattr(write_fd, TCSANOW, &newtio) < 0)
	{
		close(read_fd);
		close(write_fd);
		throw std::runtime_error("could not set baudrate for " + this->devicename);
	}

	std::cerr << "opened device " << devicename << " with baudrate " << baudrate;
}

SerialBase::~SerialBase() {
	close(read_fd);
	close(write_fd);
}

void SerialBase::write_hdlc(const std::vector<unsigned char> &packet) {
	std::vector<unsigned char> encoded;

	encoded.push_back(HDLC_SYN);
	for (unsigned char c : packet) {
		if (c == HDLC_SYN || c == HDLC_ESC) {
			encoded.push_back(HDLC_ESC);
			c ^= HDLC_XOR;
		}
		encoded.push_back(c);
	}
	encoded.push_back(HDLC_SYN);

	std::lock_guard<std::mutex> lock(write_mutex);

	int sent = 0;
	do {
		int n = write(write_fd, encoded.data() + sent, encoded.size() - sent);
		if (n < 0)
			throw std::runtime_error(get_name() + ": write failed with ");	// TODO: add number
		else
			sent += n;
	} while (sent < encoded.size());
}
