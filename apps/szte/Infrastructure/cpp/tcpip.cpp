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

#include "tcpip.hpp"
#include <csignal>
#include <cstring>

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <fcntl.h>
#include <unistd.h>
#include <poll.h>

// ------- TcpClient

TcpClient::TcpClient(const char *hostname, const char *port)
	: hostname(hostname), in(bind(&TcpClient::send, this)) {

	socket_fd = -1;
	pipe_fds[0] = -1;
	pipe_fds[1] = -1;
	struct addrinfo *result = NULL;

	try {
		struct addrinfo hints;
		memset(&hints, 0, sizeof hints);
		hints.ai_family = AF_UNSPEC;
		hints.ai_socktype = SOCK_STREAM;
		hints.ai_protocol = 0;

		int err = getaddrinfo(hostname, port, &hints, &result);
		if (err != 0)
			error("Host resolution", err);

		for (struct addrinfo *r = result; r != NULL; r = r->ai_next) {
			socket_fd = socket(r->ai_family, r->ai_socktype | SOCK_CLOEXEC, r->ai_protocol);
			if (socket_fd == -1)
				err = errno;
			else if (connect(socket_fd, r->ai_addr, r->ai_addrlen) == -1) {
				err = errno;
				close(socket_fd);
				socket_fd = -1;
			}
			else
				break;
		}

		freeaddrinfo(result);
		result = NULL;

		if (socket_fd == -1)
			error("Connection", err);

		unsigned char buff[2];
		buff[0] = 'U';
		buff[1] = ' ';

		int count = 0;
		while (count < 2) {
			ssize_t n = write(socket_fd, buff + count, 2 - count);
			if (n < 0) {
				if (errno == EINTR)
					continue;
				else
					error("Handshake", errno);
			}
			else
				count += n;
		}

		count = 0;
		while (count < 2) {
			ssize_t n = read(socket_fd, buff + count, 2 - count);
			if (n < 0) {
				if (errno == EINTR)
					continue;
				else
					error("Handshake", errno);
			}
			else
				count += n;
		}

		if (buff[0] != 'U' || buff[1] != ' ')
			throw std::runtime_error("Protocol mismatch with " + this->hostname);

		if (pipe2(pipe_fds, O_NONBLOCK | O_CLOEXEC) != 0)
			error("Creating pipe", errno);

		std::cerr << "Opened " << hostname << " with port " << port << std::endl;
	}
	catch(const std::exception &e) {
		if (socket_fd != -1)
			close(socket_fd);
		if (pipe_fds[0] != -1)
			close(pipe_fds[0]);
		if (pipe_fds[1] != -1)
			close(pipe_fds[1]);
		if (result != NULL)
			freeaddrinfo(result);

		throw;
	}
}

TcpClient::~TcpClient() {
	abort();

	close(socket_fd);
	close(pipe_fds[0]);
	close(pipe_fds[1]);

	std::cerr << "Closed " << hostname << std::endl;
}

void TcpClient::start() {
	if (pump_thread != NULL)
		throw std::runtime_error("Already started");

	pump_thread.reset(new std::thread(&TcpClient::pump, this));
}

void TcpClient::stop() {
	std::lock_guard<std::mutex> lock(mutex);

	unsigned char data = 0;
	ssize_t ignore = write(pipe_fds[1], &data, 1);
	(void) ignore;

	if (pump_thread != NULL)
		pump_thread->join();
}

void TcpClient::send(const std::vector<unsigned char> &packet) {
	std::lock_guard<std::mutex> lock(mutex);

	uint sent = 0;
	do {
		ssize_t n = write(socket_fd, packet.data() + sent, packet.size() - sent);
		if (n < 0) {
			if (errno == EINTR)
				continue;
			else
				error("Write", errno);
		}
		else
			sent += n;
	} while (sent < packet.size());
}

void TcpClient::pump() {
	struct pollfd fds[2];
	fds[0].fd = pipe_fds[0];
	fds[0].events = POLLIN;
	fds[1].fd = socket_fd;
	fds[1].events = POLLIN;

	std::vector<unsigned char> buffer;
	uint pos;

	for(;;) {
		int a = poll(fds, 2, -1);
		if (a < 0)
			error("Poll", errno);

		if (fds[0].revents != 0)
			return;
		else if (fds[1].revents != 0) {
			if (pos == 0)
				buffer.resize(1);

			assert(buffer.size() > pos);
			ssize_t n = read(socket_fd, buffer.data() + pos, buffer.size() - pos);
			if (n == -1) {
				if (errno == EINTR)
					continue;
				else
					error("Read", errno);
			}
			else if (n == 0) {
				std::cerr << "Disconnected " << hostname << std::endl;
				break;
			}
			else
				pos += n;

			assert(pos >= 1 && pos <= buffer.size());
			if (pos == static_cast<uint>(buffer[0]) + 1) {
				out.send(buffer);
				buffer.clear();
				pos = 0;
			}
		}
	}
}

void TcpClient::error(const char *msg, int err) {
	throw std::runtime_error(std::string(msg) + " failed for " + hostname + ": " + std::strerror(err));
}
