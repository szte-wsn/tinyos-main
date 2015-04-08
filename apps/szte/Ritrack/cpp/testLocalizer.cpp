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
#include "filter.hpp"
#include "Localizer.hpp"
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/contrib/contrib.hpp>

int main(int argc, char *argv[]) {
	//infrasturcture nodes
	Mote moteA(1,-3.70, 0.09);
	Mote moteB(2,-3.60, 0.09);
	Mote moteC(3,-11.59, 5.90);
	Mote moteD(4,-11.59, 5.80);
	Mote moteE(5,-8.24,10.48);
	Mote moteF(6,-8.14,10.48);
	Mote moteG(7,-0.09, 4.86);
	Mote moteH(8,-0.09, 4.76);
	/*Mote moteA(1,0.00, 0.00);
	Mote moteB(2,-0.16,0.00);
	Mote moteC(3,-4.34,2.36);
	Mote moteD(4,-4.34,2.20);
	Mote moteE(5,-0.92,4.23);
	Mote moteF(6,-0.76,4.23);
	Mote moteG(7,0.70,2.14);
	Mote moteH(8,0.70,2.30);*/
	//mobile nodes
	Mote mote9(9, 0.0, 0.0);
	
	//create config object
	Config config;
	config.addStables( { moteA,moteB,moteC,moteD,moteE,moteF,moteG,moteH } );
	config.addMobiles( { mote9 } );
	//set pairs
	config.addPairs({   			std::pair<Mote,Mote>( mote9, moteB),
						std::pair<Mote,Mote>( mote9, moteC),
						std::pair<Mote,Mote>( mote9, moteA),
						std::pair<Mote,Mote>( mote9, moteD),
						std::pair<Mote,Mote>( mote9, moteE),
						std::pair<Mote,Mote>( mote9, moteF),
						std::pair<Mote,Mote>( mote9, moteG),
						std::pair<Mote,Mote>( mote9, moteH) });


	Writer<Position<double>> writer;
	Localizer localizer(config,0.1,-50.0,50.0,1.0,-1.0);
	FrameMerger merger(50);
	BasicFilter filter(15,1);
	RipsDat ripsdat;
	RipsMsg ripsmsg;
	TosMsg tosmsg;
	Reader<std::vector<unsigned char>> reader;

	connect(reader.out, tosmsg.sub_in);
	connect(tosmsg.out, ripsmsg.in);
	connect(ripsmsg.out, ripsdat.in);
	connect(ripsdat.out, filter.in);
	connect(filter.out, merger.in);
	connect(merger.out, localizer.in);
	connect(localizer.out, writer.in);

	reader.run();
	return 0;
}
