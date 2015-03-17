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
#include <queue>
#include <cfloat>

template <typename DATA, typename PATTERN> class Viterbi {
public:
	struct Pattern {
		const std::vector<char> pattern;

		Pattern(const std::vector<char> &pattern) : pattern(pattern) { }
		virtual ~Pattern() { }
		virtual float cost(const std::vector<DATA>& vector) = 0;
	};

	struct Result {
		DATA data;
		char symbol;
		float cost;
	};

	Viterbi(uint trace_len, const std::vector<std::vector<char>> &patterns) : trace_pos(0), trace_len(trace_len) {
		if (trace_len <= 1)
			throw std::runtime_error("Viterbi: trace length must be at least two");

		pattern_len = 0;
		for (const std::vector<char> &pattern : patterns) {
			if (pattern.size() == 0)
				throw std::runtime_error("Viterbi: zero length pattern");
			else if (pattern_len == 0)
				pattern_len = pattern.size();
			else if (pattern_len != pattern.size())
				throw std::runtime_error("Viterbi: non-uniform pattern lengths");

			std::vector<char> sub;

			sub = pattern;
			sub.pop_back();
			uint src = get_state(sub);

			sub = pattern;
			sub.erase(sub.begin());
			uint dst = get_state(sub);

			edges.push_back(Edge(pattern, src, dst));
		}
	}

private:
	struct Edge : public PATTERN {
		Edge(const std::vector<char> &pattern, uint src, uint dst)
			: PATTERN(pattern), src(src), dst(dst) { }

		uint src;
		uint dst;
	};

	std::vector<Edge> edges;
	std::vector<std::vector<char>> states;

	uint get_state(const std::vector<char> &state) {
		for (uint i = 0; i < states.size(); i++)
			if (states[i] == state)
				return i;

		states.push_back(state);
		return states.size() - 1;
	}

	struct Node {
		float total_cost;
		float local_cost;
		uint src;
	};

	struct Trace {
		DATA data;
		std::vector<Node> nodes;
	};

	std::vector<Trace> traces;
	uint trace_pos;
	uint trace_len;

	std::vector<DATA> queue;
	uint pattern_len;

	static void print(std::ostream& stream, const std::vector<char> &pattern) {
		for (char c : pattern)
			stream << (int) c << " ";
	}

public:
	void butterfly(const std::vector<Node> &last, std::vector<Node> &next) {
		assert(queue.size() == pattern_len);

		for (Node &node : next)
			node.total_cost = FLT_MAX;

		for (Edge &edge : edges) {
			float local_cost = edge.cost(queue);
			float total_cost = last[edge.src].total_cost + local_cost;

			Node &dst = next[edge.dst];
			if (total_cost < dst.total_cost) {
				dst.total_cost = total_cost;
				dst.local_cost = local_cost;
				dst.src = edge.src;
			}
		}

		for (const Node &node : next)
			assert(node.total_cost != FLT_MAX);
	}

	void backtrace(Result &result) {
		assert(traces.size() == trace_len && trace_pos < trace_len);

		// trace_pos points to the oldest (next) data point
		uint pos = (trace_pos != 0 ? trace_pos : trace_len) - 1;
		const std::vector<Node> &nodes = traces[pos].nodes;

		uint best_state = 0;
		float best_cost = nodes[0].total_cost;

		for (uint i = 1; i < nodes.size(); i++) {
			if (nodes[i].total_cost < best_cost) {
				best_cost = nodes[i].total_cost;
				best_state = i;
			}
		}

		while(pos != trace_pos) {
			pos = (pos != 0 ? pos : trace_len) - 1;

			best_state = traces[pos].nodes[best_state].src;
			assert(0 <= best_state && best_state < states.size());
		}

		Trace &trace = traces[trace_pos];
		result.data = trace.data;
		result.symbol = states[best_state].front();
		result.cost = trace.nodes[best_state].local_cost;
	}

	bool decode(const DATA &data, Result &result) {
		queue.push_back(data);
		if (queue.size() < pattern_len)
			return false;

		if (traces.size() < trace_len) {
			Node empty_node;
			empty_node.src = 0;
			empty_node.local_cost = 0.0f;
			empty_node.total_cost = 0.0f;

			Trace trace;
			trace.data = queue.front();
			trace.nodes.resize(states.size(), empty_node);

			if (traces.size() == 0) {
				const std::vector<Node> last = trace.nodes;
				butterfly(last, trace.nodes);
			}
			else {
				const std::vector<Node> &last = traces.back().nodes;
				butterfly(last, trace.nodes);
			}

			traces.push_back(trace);
			queue.erase(queue.begin());

//			print(std::cout);
			return false;
		}
		else {
			backtrace(result);

			uint prev_pos = (trace_pos != 0 ? trace_pos : trace_len) - 1;
			butterfly(traces[prev_pos].nodes, traces[trace_pos].nodes);

			traces[trace_pos].data = queue.front();
			queue.erase(queue.begin());

//			print(std::cout);
			return true;
		}
	}

	void print(std::ostream& stream) {
		stream << "edges:" << std::endl;
		for (const Edge &edge : edges) {
			print(stream, edge.pattern);
			stream << "\t" << edge.src << " " << edge.dst << std::endl;
		}

		stream << "states:" << std::endl;
		for (uint i = 0; i < states.size(); i++) {
			stream << i << ": ";
			print(stream, states[i]);
			stream << std::endl;
		}

		stream.precision(2);
		stream.setf(std::ios::fixed, std::ios::floatfield);

		stream << "traces:" << std::endl;
		for (uint i = 0; i < traces.size(); i++) {
			stream << i << ":";
			for (const Node &node : traces[i].nodes)
				stream << "\t" << node.src << " " << node.local_cost << " " << node.total_cost;
			stream << std::endl;
		}

		stream << std::endl;
	}
};

class PhaseUnwrap : public Block {
public:
	struct Packet {
		ulong frame;
		float subframe;
		float range;
		float cost;
	};

	Input<RipsQuad::Packet> in;
	Output<Packet> out;

	PhaseUnwrap(uint trace_len, int length, int skips);

private:
	struct Pattern : public Viterbi<RipsQuad::Packet, Pattern>::Pattern {
		Pattern(const std::vector<char> &pattern);
		float cost(const std::vector<RipsQuad::Packet>& vector);

		std::vector<std::pair<float, float>> points;
	};

	enum {
		KEEP = 0,
		SKIP = 1,
	};

	static float get_linear_regression_error(const std::vector<std::pair<float, float>> &points);
	static float get_phase_change(float phase1, float phase2);

	static int count(const std::vector<char> &pattern, char what);
	static std::vector<std::vector<char>> make_patterns(int length, int skips);

	Viterbi<RipsQuad::Packet, Pattern> viterbi;

	float last_range;
	float last_relphase;
	void decode(const RipsQuad::Packet &packet);
};

std::ostream& operator <<(std::ostream& stream, const PhaseUnwrap::Packet &packet);

#endif//__VITERBI_HPP__
