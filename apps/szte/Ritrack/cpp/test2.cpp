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

#include "serial.hpp"
#include "packet.hpp"
#include "viterbi.hpp"

class RipsQuad2 : public Block {
public:
	struct Packet {
		ulong frame;
		float period1;
		float period2;
		float relphase1;
		float relphase2;
	};

	Input<RipsDat2::Packet> in;
	Output<Packet> out;

	RipsQuad2(uint sender1, uint sender2, uint receiver1, uint receiver2);

private:
	uint sender1, sender2, receiver1, receiver2;
	int slot1, slot2;
	float avgphase1, avgphase2, period1, period2;
	ulong lastframe;

	float calcavg(float avgphase, float relphase);

	void decode(const RipsDat2::Packet &pkt);
};

RipsQuad2::RipsQuad2(uint sender1, uint sender2, uint receiver1, uint receiver2)
	: in(bind(&RipsQuad2::decode, this)),
	sender1(sender1), sender2(sender2), receiver1(receiver1), receiver2(receiver2), slot1(-1), slot2(-1)
{
}

void RipsQuad2::decode(const RipsDat2::Packet &pkt) {
	if (pkt.sender1 != sender1 || pkt.sender2 != sender2)
		return;

	const RipsDat2::Measurement *mnt1 = pkt.get_measurement(receiver1);
	if (mnt1 == NULL || mnt1->phase == 0)
		return;

	const RipsDat2::Measurement *mnt2 = pkt.get_measurement(receiver2);
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
	assert(0.0f <= relphase && relphase < 1.0f);

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
	assert(0.0f <= avgphase && avgphase < 1.0f);
	assert(0.0f <= relphase && relphase < 1.0f);

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

int main(int argc, char *argv[]) {
	Writer<RipsQuad2::Packet> writer;
	RipsQuad2 ripsquad(1, 3, 4, 5);
	RipsDat2 ripsdat2;
	RipsDat ripsdat;
	RipsMsg ripsmsg;
	TosMsg tosmsg;
	Reader<std::vector<unsigned char>> reader;

	connect(reader.out, tosmsg.sub_in);
	connect(tosmsg.out, ripsmsg.in);
	connect(ripsmsg.out, ripsdat.in);
	connect(ripsdat.out, ripsdat2.in);
	connect(ripsdat2.out, ripsquad.in);
	connect(ripsquad.out, writer.in);

	reader.run();
	return 0;
}
