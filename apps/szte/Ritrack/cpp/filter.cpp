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

#include "filter.hpp"
#include <cstring>
#include <vector>
#include <set>
#include <cmath>

// ------- BasicFilter

BasicFilter::BasicFilter() : in(bind(&BasicFilter::decode, this)), skip_packets(1) {
}

void BasicFilter::decode(const RipsDat::Packet &packet) {
	uint c = 0;
	for (const RipsDat::Measurement &m : last_packet.measurements) {
		if (m.rssi1 >= HIGH_RSSI_LEVEL || m.rssi2 >= HIGH_RSSI_LEVEL)
			c += 1;
	}
	for (const RipsDat::Measurement &m : packet.measurements) {
		if (m.rssi1 >= HIGH_RSSI_LEVEL || m.rssi2 >= HIGH_RSSI_LEVEL)
			c += 1;
	}
	if (c >= HIGH_RSSI_COUNT)
		skip_packets = 2;

	if (skip_packets > 0)
		skip_packets -= 1;
	else {
		if (last_packet.slot >= slots.size()) {
			slots.resize(last_packet.slot + 1);
		}

		assert(last_packet.slot < slots.size());
		slots[last_packet.slot].decode(last_packet, out);
	}

	last_packet = packet;
}

BasicFilter::Slot::Slot() : history_head(0), history_size(0) {
}

void BasicFilter::Slot::decode(const RipsDat::Packet &pkt, Output<Packet> &out) {
	for (RipsDat::Measurement mnt : pkt.measurements) {
		if (mnt.period <= 0)
			continue;

		history[history_head] = mnt.period;
		if (++history_head >= HISTORY_SIZE)
			history_head = 0;

		if (history_size < HISTORY_SIZE)
			history_size += 1;
	}

	if (history_size < HISTORY_SIZE)
		return;

	int temp[HISTORY_SIZE];
	std::memcpy(temp, history, sizeof(int) * HISTORY_SIZE);

	std::sort(temp, temp + HISTORY_SIZE);

	int sum = 0;
	for (int i = 0; i < AVERAGE_SIZE; i++)
		sum += temp[(HISTORY_SIZE - AVERAGE_SIZE) / 2 + i];

	float period = sum * (1.0 / AVERAGE_SIZE);

	BasicFilter::Packet packet;
	packet.frame = pkt.frame;
	packet.slot = pkt.slot;
	packet.subframe = pkt.subframe;
	packet.sender1 = pkt.sender1;
	packet.sender2 = pkt.sender2;
	packet.period = period;

	int period_min = std::round(period * (1.0f - 0.5f / PERIOD_FRAC));
	int period_max = std::round(period * (1.0f + 0.5f / PERIOD_FRAC));

	for (const RipsDat::Measurement &mnt : pkt.measurements) {
		if (mnt.period <= 0)
			continue;

		if (period_min <= mnt.period && mnt.period <= period_max) {
			BasicFilter::Measurement measurement;

			measurement.nodeid = mnt.nodeid;
			measurement.phase = 1.0 * mnt.phase / mnt.period;
			assert(0.0f <= measurement.phase && measurement.phase < 1.0f);
			measurement.rssi1 = mnt.rssi1;
			measurement.rssi2 = mnt.rssi2;

			packet.measurements.push_back(measurement);
		}
	}

	out.send(packet);
}

std::ostream& operator <<(std::ostream& stream, const BasicFilter::Packet &packet) {
	stream.precision(2);
	stream.setf(std::ios::fixed, std::ios::floatfield);

	stream << packet.sender1 << ", " << packet.sender2 << ", " << packet.period;
	for (BasicFilter::Measurement mnt : packet.measurements) {
		stream << ",\t" << mnt.nodeid << ", " << mnt.phase;
		stream << ", " << mnt.rssi1 << ", " << mnt.rssi2;
	}

	return stream;
}

const BasicFilter::Measurement *BasicFilter::Packet::get_measurement(uint nodeid) const {
	std::vector<Measurement>::const_iterator iter = measurements.begin();
	while (iter != measurements.end()) {
		if (iter->nodeid == nodeid)
			return &*iter;

		iter++;
	}
	return NULL;
}

// ------- FrameMerger

FrameMerger::Data *FrameMerger::Slot::get_data(uint nodeid) {
	for(Data &d : data) {
		if (d.nodeid == nodeid)
			return &d;
	}
	return NULL;
}

FrameMerger::Slot *FrameMerger::Frame::get_slot(uint slotid) {
	for(Slot &slot : slots) {
		if (slot.slot == slotid)
			return &slot;
	}
	return NULL;
}

FrameMerger::FrameMerger(uint framecount) : in(bind(&FrameMerger::decode, this)),
	framecount(framecount), lastframe(0)
{
}

void FrameMerger::decode(const BasicFilter::Packet &packet) {
	ulong d = packet.frame - lastframe;
	if (d > framecount) {
		Frame frame;

		// create slots and nodes
		std::set<uint> nodes;

		for (const BasicFilter::Packet &packet : packets) {
			nodes.insert(packet.sender1);
			nodes.insert(packet.sender2);
			for (const BasicFilter::Measurement &mnt : packet.measurements)
				nodes.insert(mnt.nodeid);

			if (frame.get_slot(packet.slot) == NULL) {
				Slot slot;
				slot.slot = packet.slot;
				slot.sender1 = packet.sender1;
				slot.sender2 = packet.sender2;
				slot.period = packet.period;
				frame.slots.push_back(slot);
			}
		}

		out.send(frame);
		packets.clear();
	}

	packets.push_back(packet);
	lastframe = packet.frame;
}

std::ostream& operator <<(std::ostream& stream, const FrameMerger::Frame &frame) {
	stream.precision(2);
	stream.setf(std::ios::fixed, std::ios::floatfield);

	for (FrameMerger::Slot slot : frame.slots) {
		stream << std::setw(2) << frame.frame << ", " << std::setw(2) << slot.slot;
		stream << ", " << std::setw(2) << slot.sender1 << ", " << std::setw(2) << slot.sender2;
		stream << ", " << std::setw(4) << slot.period;

		for (FrameMerger::Data data : slot.data) {
			stream << ",\t" << std::setw(4) << data.phase;
			stream << ", " << std::setw(2) << data.rssi1;
			stream << ", " << std::setw(2) << data.rssi2;
		}
	}

	return stream;
}
