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

#ifndef __PACKET_HPP__
#define __PACKET_HPP__

#include "block.hpp"
#include <vector>
#include <utility>
#include <sstream>

uint16_t read_uint16(std::vector<unsigned char>::const_iterator pos);
uint32_t read_uint32(std::vector<unsigned char>::const_iterator pos);

inline uint8_t read_uint8(std::vector<unsigned char>::const_iterator pos) {
	return *pos;
}

inline int8_t read_int8(std::vector<unsigned char>::const_iterator pos) {
	return read_uint8(pos);
}

inline int16_t read_int16(std::vector<unsigned char>::const_iterator pos) {
	return read_uint16(pos);
}

inline int32_t read_int32(std::vector<unsigned char>::const_iterator pos) {
	return read_uint32(pos);
}

template <typename PACKET>
void runtime_error(const char *what, const PACKET &packet) {
	std::ostringstream buffer;
	buffer << what << ": " << packet;
	throw std::runtime_error(buffer.str());
}

class TosMsg : public Block {
public:
	struct Packet {
		uint16_t dst;
		uint16_t src;
		uint8_t group;
		uint8_t type;
		bool ts_valid;		// timesync message
		int32_t ts_offset;	// embedded offset
		std::vector<unsigned char> payload;
	};

	Input<std::vector<unsigned char>> sub_in;
	Output<std::vector<unsigned char>> sub_out;

	Input<Packet> in;
	Output<Packet> out;

	TosMsg(bool ignore = true);

private:
	bool ignore;

	void decode(const std::vector<unsigned char> &raw);
	void encode(const Packet &tos);
};

std::ostream& operator <<(std::ostream& stream, const TosMsg::Packet &packet);

class RipsMsg : public Block {
public:
	struct Measurement {
		int period;
		int phase;
		short rssi1;
		short rssi2;
	};

	struct Packet {
		uint nodeid;
		uint slot;
		std::vector<Measurement> measurements;
	};

	Input<TosMsg::Packet> in;
	Output<Packet> out;

	RipsMsg();

private:
	void decode(const TosMsg::Packet &tos);
	void error(const char *what, const TosMsg::Packet &tos);
};

std::ostream& operator <<(std::ostream& stream, const RipsMsg::Packet &packet);

// collects the pieces of a single RIPS measurement from different messages into a single packet
class RipsDat : public Block {
public:
	struct Measurement {
		uint nodeid;
		int period;
		int phase;
		int rssi1;
		int rssi2;
	};

	struct Packet {
		ulong frame;
		uint slot;
		float subframe;
		uint sender1;
		uint sender2;
		std::vector<Measurement> measurements;

		const Measurement *get_measurement(uint nodeid) const;
	};

	Input<RipsMsg::Packet> in;
	Output<Packet> out;

	RipsDat(const std::vector<std::vector<uint8_t>> &schedule);
	RipsDat(const char *schedule);
	RipsDat(); // find the matching schedule automatically

private:
	enum {
		TX1 = 0, //sendWave 1
		TX2 = 1, //sendWave 2
		RX = 2, //sampleRSSI
		SSYN=3, //sends sync message
		RSYN=4, //waits for sync message
		DEB = 5,
		NTRX = 6,
		NDEB = 7,
		W1 = 8,
		W10 = 9,
		W100 = 10,
		DSYN = 11,
		WCAL = 12,
	};

	static std::vector<std::vector<uint8_t>> FOUR_MOTE;
	static std::vector<std::vector<uint8_t>> SIX_MOTE;
	static std::vector<std::vector<uint8_t>> PHASEMAP_TEST_4;
	static std::vector<std::vector<uint8_t>> PHASEMAP_TEST_5;
	static std::vector<std::vector<uint8_t>> PHASEMAP_TEST_6;
	static std::vector<std::vector<uint8_t>> PHASEMAP_TEST_12;
	static std::vector<std::vector<uint8_t>> PHASEMAP_TEST_18;
	static std::vector<std::vector<uint8_t>> LOC_TEST_9_GRID;
	static std::vector<std::vector<uint8_t>> LOC_MULT_TX;
	static std::vector<std::vector<uint8_t>> LOC_4TX_4ANCHORRX;
	static std::vector<std::vector<uint8_t>> LOC_4TX_NOANCHORRX;
	static std::vector<std::vector<uint8_t>> PHASEMAP_TEST_8;
	static std::vector<std::vector<uint8_t>> MULT_RX_1;
	static std::vector<std::vector<uint8_t>> SCHEDULER_AND_RSSI_LOC_TESTER;

	static std::vector<std::pair<const char *, const std::vector<std::vector<uint8_t>>&>> NAMES;
	const std::vector<std::vector<uint8_t>> &get_schedule(const char *schedule);

	const std::vector<std::vector<uint8_t>> *schedule;

	void analize_schedule();
	uint node_count;
	uint slot_count;

	std::vector<Packet> history;
	uint get_packet_by_slot(uint slot);
	std::vector<std::vector<uint>> rx_indices; // which packet to write

	uint current_slot = 0;
	uint current_index = 0; // index into the history
	void decode(const RipsMsg::Packet &rips);
	float get_subframe(uint slot);

	void search(const RipsMsg::Packet &rips);
	std::vector<RipsMsg::Packet> backlog;
	std::vector<uint> possibilities;
	static bool contradicts(const RipsMsg::Packet &rips, const std::vector<std::vector<uint8_t>> &schedule);
};

std::ostream& operator <<(std::ostream& stream, const RipsDat::Packet &packet);

// checks the historic period for the slot and filters out outliers
class RipsDat2 : public Block {
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

	RipsDat2();

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
		bool full;

	public:
		Slot();
		void decode(const RipsDat::Packet &pkt, Output<Packet> &out);
	};

	std::vector<Slot> slots;

	void decode(const RipsDat::Packet &pkt);
};

std::ostream& operator <<(std::ostream& stream, const RipsDat2::Packet &packet);

class RipsQuad : public Block {
public:
	struct Packet {
		ulong frame;
		float subframe;
		float period;
		float relphase;
	};

	Input<RipsDat2::Packet> in;
	Output<Packet> out;

	RipsQuad(uint sender1, uint sender2, uint receiver1, uint receiver2);

private:
	uint sender1, sender2, receiver1, receiver2;

	void decode(const RipsDat2::Packet &pkt);
};

std::ostream& operator <<(std::ostream& stream, const RipsQuad::Packet &packet);

#endif//__PACKET_HPP__
