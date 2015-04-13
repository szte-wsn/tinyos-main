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

#ifndef __FILTER_HPP__
#define __FILTER_HPP__

#include "packet.hpp"
#include <complex>

// ------- BasicFilter (based on historic period and RSSI)

class BasicFilter : public Block {
public:
	struct Measurement {
		uint nodeid;
		float phase;
		int rssi1;
		int rssi2;
	};

	struct Packet {
		ulong frame;
		uint slot;
		float subframe;
		uint sender1;
		uint sender2;
		float period;
		std::vector<Measurement> measurements;

		const Measurement *get_measurement(uint nodeid) const;
	};

	Input<RipsDat::Packet> in;
	Output<Packet> out;

	BasicFilter(int high_rssi_level, int high_rssi_count);

private:
	class Slot {
	private:
		enum {
			HISTORY_SIZE = 32, // remember this many periods for this slot
			AVERAGE_SIZE = 4,  // calculate the PERIOD_MEAN as the avg of this many periods
			PERIOD_FRAC = 16,  // tolerate period error of PERIOD_MEAN / PERIOD_FRAC
		};

		int history[HISTORY_SIZE];
		uint history_head;
		uint history_size;

	public:
		Slot();
		void decode(const RipsDat::Packet &pkt, Output<Packet> &out);
	};

	std::vector<Slot> slots;

	const int high_rssi_level; // too close or produced by WIFI
	const int high_rssi_count; // a slot must have fewer high RSSI values

	uint skip_packets;
	RipsDat::Packet last_packet;
	void decode(const RipsDat::Packet &packet);
};

std::ostream& operator <<(std::ostream& stream, const BasicFilter::Packet &packet);

// ------- RipsQuad

class RipsQuad : public Block {
public:
	struct Packet {
		ulong frame;
		float subframe;
		float period;
		float relphase;
	};

	Input<BasicFilter::Packet> in;
	Output<Packet> out;

	RipsQuad(uint sender1, uint sender2, uint receiver1, uint receiver2);

private:
	uint sender1, sender2, receiver1, receiver2;

	void decode(const BasicFilter::Packet &pkt);
};

std::ostream& operator <<(std::ostream& stream, const RipsQuad::Packet &packet);

// ------- RipsQuad2

class RipsQuad2 : public Block {
public:
	struct Packet {
		ulong frame;
		float period1;
		float period2;
		float relphase1;
		float relphase2;
	};

	Input<BasicFilter::Packet> in;
	Output<Packet> out;

	RipsQuad2(uint sender1, uint sender2, uint receiver1, uint receiver2);

private:
	uint sender1, sender2, receiver1, receiver2;
	int slot1, slot2;
	float avgphase1, avgphase2, period1, period2;
	ulong lastframe;

	float calcavg(float avgphase, float relphase);

	void decode(const BasicFilter::Packet &pkt);
};

std::ostream& operator <<(std::ostream& stream, const RipsQuad2::Packet &packet);

// ------- FrameMerger

class FrameMerger : public Block {
public:
	struct Data {
		uint nodeid;
		int rssi1;			// -1 if not valid
		int rssi2;			// -1 if not valid
		float phase;			// [0.0,1.0) range, -1.0 if not valid
		float conf;			// confidence in [0.0, 1.0]
	};

	struct Slot {
		uint slot;
		uint sender1;
		uint sender2;
		float period;			// -1.0 if not valid
		std::vector<Data> data;

		const Data *get_data(uint nodeid) const;
	};

	struct Frame {
		ulong frame;
		std::vector<Slot> slots;

		const Slot *get_slot(uint slotid) const;
	};

	Input<BasicFilter::Packet> in;
	Output<Frame> out;

	FrameMerger(uint framecount);

private:
	static bool slot_order(const Slot &slot1, const Slot &slot2) {
		return slot1.slot < slot2.slot;
	}

	static bool empty_data(const Data &data) {
		return data.phase == -1.0f && data.rssi1 == -1 && data.rssi2 == -1;
	}

	const uint framecount;
	ulong lastframe;
	std::vector<BasicFilter::Packet> packets;

	void decode(const BasicFilter::Packet &pkt);
	static int average_rssi(std::vector<int> &rssi);

	static void extract_complex_phases(const std::vector<Data> &data,
		const std::vector<BasicFilter::Measurement> &measurements,
		std::vector<std::complex<float>> &output,
		std::vector<int> &counts);

	static void find_best_rotation(const std::vector<std::complex<float>> &target,
		const std::vector<std::complex<float>> &input,
		std::vector<std::complex<float>> &accum);

	static void export_complex_phases(std::vector<std::complex<float>> &input,
		const std::vector<int> &counts,
		std::vector<Data> &data);

	static void prune_data(std::vector<Data> &data);

	static std::complex<float> normalize(std::complex<float> c) {
		float a = std::abs(c);
		return a > 0.0f ? c / a : c;
	}
};

std::ostream& operator <<(std::ostream& stream, const FrameMerger::Frame &packet);

// ------- Competition

class Competition {
public:
	static uint MOBILE_NODEID;
	static std::vector<uint> RSSI_FINGERPRINT_SLOTS;

	static std::vector<float> rssi_fingerprint(const FrameMerger::Frame &frame);

	struct TrainingData {
		int id;
		float x;
		float y;
		std::vector<std::string> logfiles;
		std::vector<std::vector<float>> fingerprints;
	};

	static void read_training_data(std::vector<TrainingData> &training_data, const std::string &config = "config.txt");
	static int read_fingerprints(std::vector<std::vector<float>> &fingerprints, const std::string &logfile);

	struct StaticNode {
		int nodeid;
		float x;
		float y;
	};

	static void read_static_nodes(std::vector<StaticNode> &nodes, const std::string &config = "config.txt");

	typedef void (*localizer_func)(const FrameMerger::Frame &frame, float &x, float &y);
	static float test_harness(localizer_func func, const std::string &config = "config.txt");
};

#endif//__FILTER_HPP__
