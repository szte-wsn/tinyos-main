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
#include <fstream>
#include <sstream>

// ------- BasicFilter

BasicFilter::BasicFilter(int high_rssi_level, int high_rssi_count)
	: in(bind(&BasicFilter::decode, this)),
	high_rssi_level(high_rssi_level), high_rssi_count(high_rssi_count),
	skip_packets(1)
{
}

void BasicFilter::decode(const RipsDat::Packet &packet) {
	int c = 0;
	for (const RipsDat::Measurement &m : last_packet.measurements) {
		if (m.rssi1 >= high_rssi_level || m.rssi2 >= high_rssi_level)
			c += 1;
	}
	for (const RipsDat::Measurement &m : packet.measurements) {
		if (m.rssi1 >= high_rssi_level || m.rssi2 >= high_rssi_level)
			c += 1;
	}
	if (c >= high_rssi_count)
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
			assert(0.0f <= measurement.phase && measurement.phase <= 1.0f);
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

	stream << std::setw(2) << packet.sender1 << ", " << std::setw(2) << packet.sender2;
	stream << ", " << std::setw(2) << packet.slot << ", " << std::setw(5) << packet.period;
	for (BasicFilter::Measurement mnt : packet.measurements) {
		stream << ",  " << std::setw(2) << mnt.nodeid << ", " << std::setw(4) << mnt.phase;
		stream << ", " << std::setw(2) << mnt.rssi1 << ", " << std::setw(2) << mnt.rssi2;
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

// ------- RipsQuad

RipsQuad::RipsQuad(uint sender1, uint sender2, uint receiver1, uint receiver2)
	: in(bind(&RipsQuad::decode, this)),
	sender1(sender1), sender2(sender2), receiver1(receiver1), receiver2(receiver2)
{
}

void RipsQuad::decode(const BasicFilter::Packet &pkt) {
	if (pkt.sender1 != sender1 || pkt.sender2 != sender2)
		return;

	const BasicFilter::Measurement *mnt1 = pkt.get_measurement(receiver1);
	if (mnt1 == NULL || mnt1->phase == 0)
		return;

	const BasicFilter::Measurement *mnt2 = pkt.get_measurement(receiver2);
	if (mnt2 == NULL || mnt2->phase == 0)
		return;

	float relphase = std::fmod(mnt1->phase - mnt2->phase + 2.0f, 1.0);
	assert(0.0f <= relphase && relphase <= 1.0f);

	Packet packet;
	packet.frame = pkt.frame;
	packet.subframe = pkt.subframe;
	packet.relphase = relphase;
	packet.period = pkt.period;
	out.send(packet);
}

std::ostream& operator <<(std::ostream& stream, const RipsQuad::Packet &packet) {
	stream.precision(2);
	stream.setf(std::ios::fixed, std::ios::floatfield);

	stream << ((double) packet.frame + packet.subframe) << ", " << packet.relphase << ", " << packet.period;
	return stream;
}

// ------- RipsQuad2

RipsQuad2::RipsQuad2(uint sender1, uint sender2, uint receiver1, uint receiver2)
	: in(bind(&RipsQuad2::decode, this)),
	sender1(sender1), sender2(sender2), receiver1(receiver1), receiver2(receiver2), slot1(-1), slot2(-1)
{
}

void RipsQuad2::decode(const BasicFilter::Packet &pkt) {
	if (pkt.sender1 != sender1 || pkt.sender2 != sender2)
		return;

	const BasicFilter::Measurement *mnt1 = pkt.get_measurement(receiver1);
	if (mnt1 == NULL || mnt1->phase == 0)
		return;

	const BasicFilter::Measurement *mnt2 = pkt.get_measurement(receiver2);
	if (mnt2 == NULL || mnt2->phase == 0)
		return;

	if (pkt.frame != lastframe) {
		Packet packet;
		packet.frame = pkt.frame;
		packet.period1 = period1;
		packet.period2 = period2;
		packet.relphase1 = avgphase1;
		packet.relphase2 = avgphase2;
		out.send(packet);

		lastframe = pkt.frame;
	}

	float relphase = std::fmod(mnt1->phase - mnt2->phase + 2.0f, 1.0);
	assert(0.0f <= relphase && relphase <= 1.0f);

	if ((int) pkt.slot == slot1 || slot1 == -1) {
		slot1 = pkt.slot;
		avgphase1 = calcavg(avgphase1, relphase);
		period1 = pkt.period;
	}
	else if ((int) pkt.slot == slot2 || slot2 == -1) {
		slot2 = pkt.slot;
		avgphase2 = calcavg(avgphase2, relphase);
		period2 = pkt.period;
	}
	else {
		std::cerr << "RipsQuad2 two many slots";
	}
}

float RipsQuad2::calcavg(float avgphase, float relphase) {
	assert(0.0f <= avgphase && avgphase <= 1.0f);
	assert(0.0f <= relphase && relphase <= 1.0f);

	float d = relphase - avgphase;
	if (d > 0.5f)
		relphase -= 1.0f;
	else if (d < -0.5f)
		relphase += 1.0f;

	avgphase = 0.5f * avgphase + 0.5f * relphase;
	if (avgphase >= 1.0f)
		avgphase -= 1.0f;
	else if (avgphase < 0.0f)
		avgphase += 1.0f;

	return avgphase;
}

std::ostream& operator <<(std::ostream& stream, const RipsQuad2::Packet &packet) {
	stream.precision(2);
	stream.setf(std::ios::fixed, std::ios::floatfield);

	float relphase3 = packet.relphase1 - packet.relphase2;
	if (relphase3 < -0.5f)
		relphase3 += 1.0f;
	else if (relphase3 > 0.5f)
		relphase3 -= 1.0f;

	stream << packet.frame << ",\t" << packet.relphase1 << ", " << packet.relphase2 << ", " << relphase3;
	stream << ",\t" << packet.period1 << ", " << packet.period2;
	return stream;
}

// ------- FrameMerger

const FrameMerger::Data *FrameMerger::Slot::get_data(uint nodeid) const {
	for(const Data &d : data) {
		if (d.nodeid == nodeid)
			return &d;
	}
	return NULL;
}

const FrameMerger::Slot *FrameMerger::Frame::get_slot(uint slotid) const {
	for(const Slot &slot : slots) {
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
		frame.frame = lastframe;

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

		std::sort(frame.slots.begin(), frame.slots.end(), slot_order);

		// create empty data
		for (uint nodeid : nodes) {
			Data data;
			data.nodeid = nodeid;
			data.rssi1 = -1;
			data.rssi2 = -1;
			data.phase = -1.0f;

			for (Slot &slot : frame.slots) {
				if (slot.sender1 != nodeid && slot.sender2 != nodeid)
					slot.data.push_back(data);
			}
		}

		// compute average rssi values
		std::vector<int> rssi1;
		std::vector<int> rssi2;

		for (Slot &slot : frame.slots) {
			for (Data &data : slot.data) {
				rssi1.clear();
				rssi2.clear();

				for (const BasicFilter::Packet &packet : packets) {
					if (packet.slot == slot.slot) {
						for (const BasicFilter::Measurement &mnt : packet.measurements) {
							if (mnt.nodeid == data.nodeid) {
								rssi1.push_back(mnt.rssi1);
								rssi2.push_back(mnt.rssi2);
							}
						}
					}
				}

				data.rssi1 = average_rssi(rssi1);
				data.rssi2 = average_rssi(rssi2);
			}
		}

		std::vector<std::complex<float>> approx1;
		std::vector<std::complex<float>> approx2;

		// compute average phases
		for (Slot &slot : frame.slots) {
			std::vector<std::vector<std::complex<float>>> phases_table;

			std::vector<int> counts;
			counts.resize(slot.data.size(), 0);

			for (const BasicFilter::Packet &packet : packets) {
				if (packet.slot == slot.slot && packet.measurements.size() >= 2) {
					std::vector<std::complex<float>> phases;
					extract_complex_phases(slot.data, packet.measurements, phases, counts);
					phases_table.push_back(phases);
				}
			}

			if (phases_table.empty())
				continue;

			approx1.clear();
			approx1.resize(phases_table.front().size());

			for (const std::vector<std::complex<float>> &phases : phases_table)
				find_best_rotation(approx1, phases, approx1);

			approx2.clear();
			approx2.resize(phases_table.front().size());

			for (const std::vector<std::complex<float>> &phases : phases_table)
				find_best_rotation(approx1, phases, approx2);

			export_complex_phases(approx2, counts, slot.data);
		}

		// prune data
		for (Slot &slot : frame.slots)
			prune_data(slot.data);

		out.send(frame);
		packets.clear();
		lastframe = packet.frame;
	}

	packets.push_back(packet);
}

int FrameMerger::average_rssi(std::vector<int> &rssi) {
	if (rssi.size() == 0)
		return -1;
	else if (rssi.size() == 1)
		return rssi.front();

	std::sort(rssi.begin(), rssi.end());
	return rssi[rssi.size()/2];
}

void FrameMerger::extract_complex_phases(const std::vector<Data> &data,
	const std::vector<BasicFilter::Measurement> &measurements,
	std::vector<std::complex<float>> &output,
	std::vector<int> &counts)
{
	assert(output.empty());
	output.resize(data.size(), std::complex<float>(0.0f, 0.0f));

	assert(counts.size() == data.size());

	float TWOPI = 6.2831853f;

	for (const BasicFilter::Measurement &m : measurements) {
		if (m.phase == -1.0f)
			continue;
		assert(0.0f <= m.phase && m.phase <= 1.0f);

		uint i;
		for (i = 0; i < data.size(); i++) {
			if (data[i].nodeid == m.nodeid) {
				float p = TWOPI * m.phase;
				output[i] = std::complex<float>(std::cos(p), std::sin(p));
				counts[i] += 1;
				break;
			}
		}
	}
}

void FrameMerger::find_best_rotation(const std::vector<std::complex<float>> &target,
	const std::vector<std::complex<float>> &input,
	std::vector<std::complex<float>> &accum)
{
	assert(target.size() == input.size() && input.size() == accum.size());

	std::complex<float> s(0.0f, 0.0f);
	for(uint i = 0; i < input.size(); i++)
		s += normalize(target[i]) * std::conj(input[i]);

	float a = std::abs(s);
	if (a <= 0.0f) {
		for (uint i = 0; i < input.size(); i++)
			accum[i] += input[i];
	}
	else {
		s = s/a;
		for (uint i = 0; i < input.size(); i++)
			accum[i] += input[i] * s;
	}
}

void FrameMerger::export_complex_phases(std::vector<std::complex<float>> &input,
	const std::vector<int> &counts,
	std::vector<Data> &data)
{
	assert(input.size() == data.size());

	float TWOPI = 6.2831853f;

	for (uint i = 0; i < data.size(); i++) {
		std::complex<float> c = input[i];
		if (counts[i] <= 0 || (c.real() == 0.0f && c.imag() == 0.0f)) {
			data[i].phase = -1.0;
			data[i].conf = 0.0;
		}
		else {
			float a = std::arg(c) / TWOPI;
			assert(-0.5f <= a && a <= 0.5f);

			if (a < 0.0f)
				a += 1.0f;

			data[i].phase = a;
			data[i].conf = std::abs(c) / (1 + counts[i]);
		}
	}
}

void FrameMerger::prune_data(std::vector<Data> &data) {
	data.erase(std::remove_if(data.begin(), data.end(), empty_data), data.end());

	float p = -1.0f;
	for (Data &d : data) {
		if (d.phase != -1.0f) {
			assert(0.0f <= d.phase && d.phase <= 1.0f);

			if (p == -1.0f)
				p = d.phase;

			float q = d.phase - p;
			if (q < 0.0f)
				q += 1.0f;

			assert(0.0f <= q && q <= 1.0f);
			d.phase = q;
		}
	}
}

std::ostream& operator <<(std::ostream& stream, const FrameMerger::Frame &frame) {
	stream.precision(2);
	stream.setf(std::ios::fixed, std::ios::floatfield);

	for (FrameMerger::Slot slot : frame.slots) {
		// stream << std::setw(2) << frame.frame << ", " << std::setw(2) << slot.slot << ", ";
		stream << std::setw(2) << slot.sender1 << "," << std::setw(2) << slot.sender2 << ", " << std::setw(5) << slot.period;

		for (FrameMerger::Data data : slot.data) {
			stream << ", " << std::setw(2) << data.nodeid;
			stream << ", " << std::setw(2) << data.rssi1;
			stream << "," << std::setw(2) << data.rssi2;
			stream << ", " << std::setw(4) << data.phase;
			stream << "," << std::setw(4) << data.conf;
		}

		stream << std::endl;
	}

	return stream;
}

// ------- Competition

uint Competition::MOBILE_NODEID = 31;

std::vector<uint> Competition::RSSI_FINGERPRINT_SLOTS = { 0,1, 3,4, 7,8, 10,11, 14,15, 17,18, 21,22, 24,25, 28,29, 31,32 };

std::vector<float> Competition::rssi_fingerprint(const FrameMerger::Frame &frame) {
	std::vector<float> fingerprint;

	for (uint slotid : RSSI_FINGERPRINT_SLOTS) {
		const FrameMerger::Slot *slot = frame.get_slot(slotid);
		const FrameMerger::Data *data = slot != NULL ? slot->get_data(MOBILE_NODEID) : NULL;

		fingerprint.push_back(data != NULL ? data->rssi1 : -1.0f);
		fingerprint.push_back(data != NULL ? data->rssi2 : -1.0f);
	}

	return fingerprint;
}

std::vector<float> Competition::rips_fingerprint(const FrameMerger::Frame &frame) {
	std::vector<float> fingerprint;

	float TWOPI = 6.2831853f;

	for (uint slotid : RSSI_FINGERPRINT_SLOTS) {
		const FrameMerger::Slot *slot = frame.get_slot(slotid);
		const FrameMerger::Data *data = slot != NULL ? slot->get_data(MOBILE_NODEID) : NULL;

		if (data == NULL || slot->data.size() < 2 || data->phase == -1.0f) {
			fingerprint.push_back(0.0f);
			fingerprint.push_back(0.0f);
		}
		else {
			assert(0.0f <= data->phase && data->phase <= 1.0f);
			assert(0.0f <= data->conf && data->conf <= 1.0f);

			fingerprint.push_back(data->conf * std::cos(data->phase * TWOPI));
			fingerprint.push_back(data->conf * std::sin(data->phase * TWOPI));
		}
	}

	return fingerprint;
}

std::vector<float> Competition::both_fingerprint(const FrameMerger::Frame &frame) {
	std::vector<float> fingerprint = rssi_fingerprint(frame);

	std::vector<float> temp = rips_fingerprint(frame);
	for (float a : temp)
		fingerprint.push_back(a * 2.0f);

	return fingerprint;
}

std::vector<float> Competition::which_fingerprint(int which, const FrameMerger::Frame &frame) {
	if (which == 0)
		return rssi_fingerprint(frame);
	else if (which == 1)
		return rips_fingerprint(frame);
	else if (which == 2)
		return both_fingerprint(frame);
	else
		throw std::runtime_error("Invalid fingerprint selector");
}

void Competition::read_training_data(std::vector<TrainingData> &training_data, int which, const std::string &config) {
	training_data.clear();

	std::ifstream config_ifs;
	config_ifs.open(config, std::ifstream::in);
	if (config_ifs.fail())
		throw std::runtime_error("Could not open config file: " + config);

	int fingerprint_count = 0;

	const int MAXLEN = 5000;
	char line[MAXLEN];
	while (config_ifs.good()) {
		line[0] = 0;
		config_ifs.getline(line, MAXLEN);

		std::istringstream stream(line);
		stream >> std::ws;
		if (stream.eof() || stream.peek() == '#')
			continue;

		std::string type;
		stream >> type >> std::ws;
		if (type.compare("log") != 0)
			continue;

		TrainingData data;
		data.id = training_data.size();

		stream >> data.x >> std::ws >> data.y >> std::ws;
		if (!stream.good()) {
			std::cerr << "Invalid config line: " << line << std::endl;
			continue;
		}

		while (stream.good()) {
			std::string logfile;
			stream >> logfile >> std::ws;
			data.logfiles.push_back(logfile);

			std::cout << "Reading " << logfile << "\tfor " << data.x << " " << data.y << std::endl;
			fingerprint_count += read_fingerprints(data.fingerprints, which, logfile);
		}

		if (data.fingerprints.size() != 0)
			training_data.push_back(data);
	}

	std::cout << "TOTAL FINGERPRINTS: " << fingerprint_count << std::endl;
	config_ifs.close();
}

int Competition::read_fingerprints(std::vector<std::vector<float>> &fingerprints, int which, const std::string &logfile) {
	std::ifstream log;
	log.open(logfile, std::ifstream::in);
	if (log.fail())
		throw std::runtime_error("Could not open logfile: " + logfile);

	Collector<FrameMerger::Frame> collector;
	FrameMerger merger(20);
	BasicFilter filter(99, 3);
	RipsDat ripsdat;
	RipsMsg ripsmsg;
	TosMsg tosmsg;
	Reader<std::vector<unsigned char>> reader(log);

	connect(reader.out, tosmsg.sub_in);
	connect(tosmsg.out, ripsmsg.in);
	connect(ripsmsg.out, ripsdat.in);
	connect(ripsdat.out, filter.in);
	connect(filter.out, merger.in);
	connect(merger.out, collector.in);

	reader.run();
	reader.wait();

	std::vector<FrameMerger::Frame> result = collector.get_result();
	int count = std::min(10, (int) result.size());

	for (uint i = result.size() - count; i < result.size(); i++)
		fingerprints.push_back(which_fingerprint(which, result[i]));

	log.close();
	return count;
}

void Competition::read_static_nodes(std::vector<StaticNode> &nodes, const std::string &config) {
	nodes.clear();

	std::ifstream config_ifs;
	config_ifs.open(config, std::ifstream::in);
	if (config_ifs.fail())
		throw std::runtime_error("Could not open config file: " + config);

	const int MAXLEN = 5000;
	char line[MAXLEN];
	while (config_ifs.good()) {
		line[0] = 0;
		config_ifs.getline(line, MAXLEN);

		std::istringstream stream(line);
		stream >> std::ws;
		if (stream.eof() || stream.peek() == '#')
			continue;

		std::string type;
		stream >> type >> std::ws;
		if (type.compare("node") != 0)
			continue;

		StaticNode node;
		stream >> node.nodeid >> std::ws;
		stream >> node.x >> std::ws;
		stream >> node.y >> std::ws;

		if (stream.fail() || !stream.eof()) {
			std::cerr << "Invalid config line: " << line << std::endl;
			continue;
		}

		nodes.push_back(node);
	}
}

float Competition::test_harness(localizer_func func, const std::string &config) {
	std::ifstream config_ifs;
	config_ifs.open(config, std::ifstream::in);
	if (config_ifs.fail())
		throw std::runtime_error("Could not open config file: " + config);

	float avg_error = 0.0f;
	int avg_count = 0;

	const int MAXLEN = 5000;
	char line[MAXLEN];
	while (config_ifs.good()) {
		line[0] = 0;
		config_ifs.getline(line, MAXLEN);

		std::istringstream stream(line);
		stream >> std::ws;
		if (stream.eof() || stream.peek() == '#')
			continue;

		std::string type;
		stream >> type >> std::ws;
		if (type.compare("test") != 0)
			continue;

		float x, y;
		std::string logfile;

		stream >> x >> std::ws >> y >> std::ws >> logfile >> std::ws;

		if (stream.fail() || !stream.eof()) {
			std::cerr << "Invalid config line: " << line << std::endl;
			continue;
		}

		std::ifstream log;
		log.open(logfile, std::ifstream::in);
		if (log.fail())
			throw std::runtime_error("Could not open logfile: " + logfile);

		Collector<FrameMerger::Frame> collector;
		FrameMerger merger(20);
		BasicFilter filter(99, 3);
		RipsDat ripsdat;
		RipsMsg ripsmsg;
		TosMsg tosmsg;
		Reader<std::vector<unsigned char>> reader(log);

		connect(reader.out, tosmsg.sub_in);
		connect(tosmsg.out, ripsmsg.in);
		connect(ripsmsg.out, ripsdat.in);
		connect(ripsdat.out, filter.in);
		connect(filter.out, merger.in);
		connect(merger.out, collector.in);

		reader.run();
		reader.wait();

		std::vector<FrameMerger::Frame> result = collector.get_result();
		if (result.size() < 1)
			throw std::runtime_error("Logfile " + logfile + " has no valid frame");

		float x2 = 0.0f;
		float y2 = 0.0f;

		func(result.back(), x2, y2);

		float e = std::sqrt((x2-x)*(x2-x) + (y2-y)*(y2-y));

		std::cout << "Testing " << logfile << " " << x << " " << y << " with " << result.size() << " frames ";
		std::cout << "\t pos: " << x2 << " " << y2 << " err: " << e << std::endl;

		avg_error += e;
		avg_count += 1;
	}

	float e = avg_count > 0 ? avg_error / avg_count : 0.0f;
	std::cout << "AVG ERROR: " << e << std::endl;

	return e;
}
