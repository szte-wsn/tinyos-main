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
#include <utility>

template <typename DATA, typename PATTERN> class Viterbi {
public:
	class Pattern {
	public:
		Pattern(const std::vector<char> &pattern) : pattern(pattern) { }
		virtual float error(const DATA& data) const = 0;

		std::vector<char> pattern;
	};

	Viterbi(const std::vector<PATTERN> &patterns) : patterns(patterns) {
	}

	std::pair<DATA, char> decode(const DATA &data) {
		return std::make_pair(data, 0);
	}

private:
	std::vector<PATTERN> patterns;
};

class UnwrapQuad : public Block {
public:
	enum {
		KEEP = 0,
		SKIP = 1,
	};

	struct Packet {
		ulong frame;
		float subframe;
		float range;
		float error;
	};

	Input<RipsQuad::Packet> in;
	Output<Packet> out;

	UnwrapQuad();

private:
	class Pattern : public Viterbi<RipsQuad::Packet, Pattern>::Pattern {
		Pattern(const std::vector<char> &pattern);
		float error(const RipsQuad::Packet& data) const;
	};

	const std::vector<Pattern> patterns;
	Viterbi<RipsQuad::Packet, Pattern> viterbi;

	void decode(const RipsQuad::Packet &packet);
};

#endif//__VITERBI_HPP__
