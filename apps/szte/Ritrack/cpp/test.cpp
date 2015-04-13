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

#include "filter.hpp"
#include "Localizer.hpp"

void localizer_null(const FrameMerger::Frame &frame, float &x, float &y) {
	x = 0.0f;
	y = 0.0f;
}

class Test {
public:
	Collector<Position<double>> collector;
	Localizer localizer;
	Generator<FrameMerger::Frame> generator;

	Test() : localizer(0.05,-50.0,50.0,0.0,0.0) {
		connect(generator.out, localizer.in);
		connect(localizer.out, collector.in);
	}

	void test(const FrameMerger::Frame &frame, float &x, float &y) {
		collector.clear();
		generator.run(frame);
		std::vector<Position<double>> result = collector.get_result();
		assert(result.size() == 1);

		if(result.size() != 0) {
			x = result.back().getX();
			y = result.back().getY();
		}
	}
};

Test *test = NULL;

void localizer_rssi(const FrameMerger::Frame &frame, float &x, float &y){
	if (test == NULL)
		test = new Test();

	test->test(frame, x, y);
}

int main(int argc, char *argv[]) {

	Competition::test_harness(localizer_rssi);
}
