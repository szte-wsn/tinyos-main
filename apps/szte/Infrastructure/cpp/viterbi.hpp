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

#ifndef __VITERBI_HPP__
#define __VITERBI_HPP__

#include "block.hpp"
#include "packet.hpp"
#include <vector>

template <typename DATA, typename PATTERN> class Viterbi {
public:
	struct Pattern {
		virtual const std::vector<char> & get_pattern() = 0;
		virtual float error(const std::vector<DATA>& vector) = 0;

		void print(std::ostream& stream) {
			const std::vector<char> &pattern = get_pattern();
			for (char c : pattern)
				stream << (int) c << " ";
			stream << "\n";
		}
	};

	struct Result {
		DATA data;
		char state;
		float error;
	};

	Viterbi(const std::vector<PATTERN> &patterns) : patterns(patterns) {
	}

	Result decode(const DATA &data) {
		Result result;

		result.data = data;
		result.state = 0;
		result.error = 0.0f;

		return result;
	}

private:
	std::vector<PATTERN> patterns;
};

class PhaseUnwrap : public Block {
public:
	struct Packet {
		ulong frame;
		float subframe;
		float range;
		float error;
	};

	Input<RipsQuad::Packet> in;
	Output<Packet> out;

	PhaseUnwrap(int length, int skips);

private:
	struct Pattern : public Viterbi<RipsQuad::Packet, Pattern>::Pattern {
		Pattern(const std::vector<char> &pattern) : pattern(pattern) { }
		std::vector<char> pattern;

		const std::vector<char> & get_pattern() { return pattern; }
		float error(const std::vector<RipsQuad::Packet>& vector);

		std::vector<std::pair<float, float>> points;
	};

	enum {
		KEEP = 0,
		SKIP = 1,
	};

	static float get_linear_regression_error(const std::vector<std::pair<float, float>> &points);
	static float get_phase_change(float phase1, float phase2);

	static int count(const std::vector<char> &pattern, char what);
	static std::vector<Pattern> make_patterns(int length, int skips);

	const std::vector<Pattern> patterns;
	Viterbi<RipsQuad::Packet, Pattern> viterbi;

	float last_relphase;
	void decode(const RipsQuad::Packet &packet);
};

std::ostream& operator <<(std::ostream& stream, const PhaseUnwrap::Packet &packet);

#endif//__VITERBI_HPP__
