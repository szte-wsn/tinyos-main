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

#include "block.hpp"
#include "serial.hpp"
#include "compat.hpp"
#include <algorithm>

bool parse_flag(int argc, char *argv[], const std::string &flag) {
	return std::find(argv + 1, argv + argc, flag) != (argv + argc);
}

const char *parse_arg(int argc, char *argv[], const std::string &flag, const char *def) {
	char **end = argv + argc;
	char **itr = std::find(argv + 1, end, flag) + 1;
	return itr < end ? *itr : def;
}

int main(int argc, char *argv[]) {
	if (parse_flag(argc, argv, "-h") || parse_flag(argc, argv, "--help")) {
		std::cerr << "Usage: recorder [-h] [-d device] [-b baudrate]\n";
		return 1;
	}

	const char *device = parse_arg(argc, argv, "-d", "/dev/ttyACM0");
	int baudrate = std::stoi(parse_arg(argc, argv, "-b", "57600"));

	Writer<std::vector<unsigned char>> writer;
	Buffer<std::vector<unsigned char>> buffer;
	Serial serial(device, baudrate);

	connect(serial.out, buffer.in);
	connect(buffer.out, writer.in);

	wait_for_sigint();
	return 0;
}
