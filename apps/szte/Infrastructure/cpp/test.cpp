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
#include "packet.hpp"

class MyPrinter : public Transform<RipsDat::Packet, std::string> {
	std::string transform(const RipsDat::Packet &packet) {
		std::stringstream stream;

		int min_period = 999;
		int max_period = 0;

		for (int i = 3; i <= 8; i++) {
			const RipsDat::Measurement *m = packet.get_measurement(i);
			int period = m != NULL ? m->period : 0;
			int phase = m != NULL ? m->phase : 100;

			if (period != 0) {
				if (period < min_period)
					min_period = period;
				if (period > max_period)
					max_period = period;
			}

			if (i != 3)
				stream << ", ";

			stream << period << ", " << phase;
		}

		int period = max_period - min_period <= 4 ? (max_period + min_period) / 2 : 0;
		stream << ", " << period;

		return stream.str();
	}
};

int main(int argc, char *argv[]) {
	Writer<std::string> writer;
	MyPrinter printer;
	RipsDat ripsdat;
	RipsMsg ripsmsg;
	TosMsg tosmsg;
	Reader<std::vector<unsigned char>> reader;

	connect(reader.out, tosmsg.sub_in);
	connect(tosmsg.out, ripsmsg.sub_in);
	connect(ripsmsg.out, ripsdat.sub_in);
	connect(ripsdat.out, printer.in);
	connect(printer.out, writer.in);
	reader.run();
	return 0;
}
