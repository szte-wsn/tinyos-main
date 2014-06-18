/** Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Miklos Maroti
*/

#include "EchoRanger.h"

configuration EchoRangerC
{
	provides
	{
		interface Set<uint8_t> as SetCoarseGain;
		interface Set<uint8_t> as SetFineGain;
		interface Set<uint8_t> as SetWait;
	  
		interface Read<echorange_t*> as EchoRanger;
		interface ReadRef<uint16_t> as LastBuffer;
	}
}

implementation
{
	components EchoRangerM;
	components MainC;
	components NoLedsC as LedsC;
	#ifdef PLATFORM_IRIS
	components new AlarmOne16C() as AlarmC;
	#else
	components new AlarmMicro32C() as AlarmC;
	#endif
	components MicrophoneC;
	components MicaBusC;
	components LocalTimeMicroC;
	#ifdef PLATFORM_IRIS
	components new NoReadInt16C(10) as TempC;
	#else
	components new AtmegaTemperatureC() as TempC;
	#endif
	components new BuzzerC();

	EchoRangerM.Boot -> MainC;
	EchoRangerM.Leds -> LedsC;
	EchoRangerM.MicRead ->	MicrophoneC;
	EchoRangerM.FirstAmp -> MicrophoneC.FirstAmp;
	EchoRangerM.SecondAmp -> MicrophoneC.SecondAmp;
	EchoRangerM.Alarm -> AlarmC;
	EchoRangerM.SounderPin -> BuzzerC;	// from SounderC
	EchoRangerM.LocalTime -> LocalTimeMicroC;
	EchoRangerM.ReadTemp -> TempC;

	SetCoarseGain = EchoRangerM.SetCoarseGain;
	SetFineGain = EchoRangerM.SetFineGain;
	SetWait = EchoRangerM.SetWait;
	EchoRanger = EchoRangerM;
	LastBuffer = EchoRangerM.LastBuffer;
}
