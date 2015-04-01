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

	BasicFilter();

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

	enum {
		HIGH_RSSI_LEVEL = 10,	// too close or produced by WIFI
		HIGH_RSSI_COUNT = 3,	// a single slot must have fewer high RSSI values
	};

	uint skip_packets;
	RipsDat::Packet last_packet;
	void decode(const RipsDat::Packet &packet);
};

std::ostream& operator <<(std::ostream& stream, const BasicFilter::Packet &packet);

// ------- FrameMerger

class FrameMerger : public Block {
public:
	struct Data {
		uint nodeid;
		float phase;			// [0.0,1.0) range, -1.0 if not valid
		int rssi1;			// -1 if not valid
		int rssi2;			// -1 if not valid
	};

	struct Slot {
		uint slot;
		uint sender1;
		uint sender2;
		float period;			// -1.0 if not valid
		std::vector<Data> data;

		Data *get_data(uint nodeid);
	};

	struct Frame {
		ulong frame;
		std::vector<Slot> slots;

		Slot *get_slot(uint slotid);
	};

	Input<BasicFilter::Packet> in;
	Output<Frame> out;

	FrameMerger(uint framecount);

private:
	const uint framecount;
	ulong lastframe;
	std::vector<BasicFilter::Packet> packets;

	void decode(const BasicFilter::Packet &pkt);
};

std::ostream& operator <<(std::ostream& stream, const FrameMerger::Frame &packet);

#endif//__FILTER_HPP__
