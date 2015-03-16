/*
 * Copyright (c) 2015, University of Szeged
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

#include "viterbi.hpp"

// ------- PhaseUnwrap

PhaseUnwrap::PhaseUnwrap(int length, int skips)
	: in(bind(&PhaseUnwrap::decode, this)),
	viterbi(make_patterns(length, skips)),
	last_relphase(0.0f)
{
}

int PhaseUnwrap::count(const std::vector<char> &pattern, char what) {
	int a = 0;

	for (char c : pattern)
		if (c == what)
			a += 1;

	return a;
}

std::vector<std::vector<char>> PhaseUnwrap::make_patterns(int length, int skips) {
	std::vector<std::vector<char>> patterns;

	std::vector<char> pattern;
	for (int i = 0; i < length; i++)
		pattern.push_back(KEEP);

	patterns.push_back(pattern);
	do {
		int i = 0;
		do {
			pattern[i] += 1;
			if (pattern[i] > SKIP ) {
				pattern[i] = KEEP;
				i += 1;
				continue;
			}
			else if (count(pattern, SKIP) <= skips) {
				patterns.push_back(pattern);
				break;
			}
		} while (i < length);
	} while (count(pattern, KEEP) != length);

	return patterns;
}

float PhaseUnwrap::get_linear_regression_error(const std::vector<std::pair<float, float>> &points) {
	assert(points.size() >= 1);

	float n = points.size();
	float x = 0.0f, y = 0.0f, x2 = 0.0f, xy = 0.0f;
	for (std::pair<float, float> point : points) {
		x += point.first;
		y += point.second;
		x2 += point.first * point.first;
		xy += point.first * point.second;
	}

	float b = (n * xy - x * y) / (n * x2 - x * x);
	float a = y - b * x;

	float e = 0.0f;
	for (std::pair<float, float> point : points) {
		float z = a + b * point.first - point.second;
		e += z * z;
	}

	return e;
}

float PhaseUnwrap::get_phase_change(float phase1, float phase2) {
	float p = phase2 - phase1;

	assert(-1.0f < p && p < 1.0f);
	if (p < -0.5f)
		p += 1.0f;
	else if (p > 0.5f)
		p -= 1.0f;
	assert(-0.5f <= p && p <= 0.5f);

	return p;
}

float PhaseUnwrap::Pattern::error(const std::vector<RipsQuad::Packet>& vector) {
	assert(vector.size() == pattern.size());

	points.clear();
	ulong base = vector[0].frame;
	float last = 0.0f;
	float unwrap = 0.0f;

	for (uint i = 0; i < vector.size(); i++) {
		if (pattern[i] == KEEP) {
			float relphase = vector[i].relphase;
			unwrap += get_phase_change(last, relphase);
			last = relphase;

			float x = vector[i].subframe + (float) (vector[i].frame - base);
			points.push_back(std::make_pair(x, unwrap));
		}
	}

	return get_linear_regression_error(points);
}

void PhaseUnwrap::decode(const RipsQuad::Packet &packet) {
	Viterbi<RipsQuad::Packet, Pattern>::Result result = viterbi.decode(packet);

	if (result.symbol == KEEP) {
		Packet decoded;

		decoded.frame = result.data.frame;
		decoded.subframe = result.data.subframe;
		decoded.range = get_phase_change(last_relphase, result.data.relphase);
		last_relphase = result.data.relphase;
		decoded.error = result.error;

		out.send(decoded);
	}
}

std::ostream& operator <<(std::ostream& stream, const PhaseUnwrap::Packet &packet) {
	stream.precision(2);
	stream.setf(std::ios::fixed, std::ios::floatfield);

	stream << (double) packet.frame + packet.subframe;
	stream << ", " << packet.range << ", " << packet.error;

	return stream;
}
