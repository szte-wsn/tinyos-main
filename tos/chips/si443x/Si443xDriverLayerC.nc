/*
 * Copyright (c) 2007, Vanderbilt University
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
 * Author: Krisztian Veress
 */

#include <RadioConfig.h>

configuration Si443xDriverLayerC
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
		interface RadioPacket;

		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface LinkPacketMetadata;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface Alarm<TRadio, tradio_size>;
	}

	uses
	{
		interface Si443xDriverConfig as Config;
		interface PacketTimeStamp<TRadio, uint32_t>;

		interface PacketFlag as TransmitPowerFlag;
		interface PacketFlag as RSSIFlag;
		interface PacketFlag as TimeSyncFlag;
		interface RadioAlarm;
	}
}

implementation
{
	components Si443xDriverLayerP, HplSi443xC, BusyWaitMicroC, TaskletC;

	// provides
	RadioState = Si443xDriverLayerP;
	RadioSend = Si443xDriverLayerP;
	RadioReceive = Si443xDriverLayerP;
	RadioCCA = Si443xDriverLayerP;
	RadioPacket = Si443xDriverLayerP;

	PacketTransmitPower = Si443xDriverLayerP.PacketTransmitPower;
	PacketRSSI = Si443xDriverLayerP.PacketRSSI;
	PacketTimeSyncOffset = Si443xDriverLayerP.PacketTimeSyncOffset;
	PacketLinkQuality = Si443xDriverLayerP.PacketLinkQuality;
	LinkPacketMetadata = Si443xDriverLayerP;

	LocalTimeRadio = HplSi443xC;
	Alarm = HplSi443xC.Alarm;

	// uses
	Config = Si443xDriverLayerP;
	PacketTimeStamp = Si443xDriverLayerP.PacketTimeStamp;
	

	TransmitPowerFlag = Si443xDriverLayerP.TransmitPowerFlag;
	RSSIFlag = Si443xDriverLayerP.RSSIFlag;
	TimeSyncFlag = Si443xDriverLayerP.TimeSyncFlag;
	RadioAlarm = Si443xDriverLayerP.RadioAlarm;

	Si443xDriverLayerP.SDN -> HplSi443xC.SDN;
	Si443xDriverLayerP.NSEL -> HplSi443xC.NSEL;
	Si443xDriverLayerP.IRQ -> HplSi443xC.IRQ;
//	Si443xDriverLayerP.IRQInit -> HplSi443xC.IRQInit;

	Si443xDriverLayerP.FastSpiByte -> HplSi443xC;
	Si443xDriverLayerP.SpiResource -> HplSi443xC.SpiResource;

	Si443xDriverLayerP.BusyWait -> BusyWaitMicroC;
	Si443xDriverLayerP.LocalTime -> HplSi443xC;

	Si443xDriverLayerP.Tasklet -> TaskletC;

#ifdef RADIO_DEBUG
	components DiagMsgC, AssertC;
	Si443xDriverLayerP.DiagMsg -> DiagMsgC;
	Si443xDriverLayerP.Boot -> MainC;
#endif

	components RealMainP, MainC;
	RealMainP.PlatformInit -> Si443xDriverLayerP.PlatformInit;
	MainC.SoftwareInit -> Si443xDriverLayerP.SoftwareInit;

}
