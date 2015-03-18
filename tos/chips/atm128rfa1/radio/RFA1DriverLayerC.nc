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
 * Author: Andras Biro
 */

#include <RadioConfig.h>
#include <RFA1DriverLayer.h>
#include "TimerConfig.h"

configuration RFA1DriverLayerC
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
		interface RFA1DriverConfig as Config;
		interface PacketTimeStamp<TRadio, uint32_t>;

		interface PacketFlag as TransmitPowerFlag;
		interface PacketFlag as RSSIFlag;
		interface PacketFlag as TimeSyncFlag;
		interface AsyncStdControl as ExtAmpControl;
		interface Tasklet;
	}
}

implementation
{
	components RFA1DriverLayerP, BusyWaitMicroC;

	RadioState = RFA1DriverLayerP;
	RadioSend = RFA1DriverLayerP;
	RadioReceive = RFA1DriverLayerP;
	RadioCCA = RFA1DriverLayerP;
	RadioPacket = RFA1DriverLayerP;

	Config = RFA1DriverLayerP;

	PacketTransmitPower = RFA1DriverLayerP.PacketTransmitPower;
	TransmitPowerFlag = RFA1DriverLayerP.TransmitPowerFlag;

	PacketRSSI = RFA1DriverLayerP.PacketRSSI;
	RSSIFlag = RFA1DriverLayerP.RSSIFlag;

	PacketTimeSyncOffset = RFA1DriverLayerP.PacketTimeSyncOffset;
	TimeSyncFlag = RFA1DriverLayerP.TimeSyncFlag;

	PacketLinkQuality = RFA1DriverLayerP.PacketLinkQuality;
	PacketTimeStamp = RFA1DriverLayerP.PacketTimeStamp;
	LinkPacketMetadata = RFA1DriverLayerP;

	Tasklet = RFA1DriverLayerP.Tasklet;
	RFA1DriverLayerP.BusyWait -> BusyWaitMicroC;

#if RFA1_RADIO_TIMER1_MCU
	components LocalTimeMcuC as LocalTimeC, new AlarmMcu32C() as AlarmC, HplAtmRfa1Timer1C, HplAtmegaCounterMcu32C;
	components new AtmegaTransformCaptureC(uint32_t, uint16_t, 0);
	
	RFA1DriverLayerP.SfdCapture -> AtmegaTransformCaptureC.HplAtmegaCapture;
	AtmegaTransformCaptureC.SubCapture -> HplAtmRfa1Timer1C;
	AtmegaTransformCaptureC.HplAtmegaCounter -> HplAtmegaCounterMcu32C;
#elif defined(RFA1_RADIO_TIMER1_MICRO)
	components LocalTimeMicroC as LocalTimeC, new AlarmMicro32C() as AlarmC, HplAtmRfa1Timer1C;
	components new AtmegaTransformCaptureC(uint32_t, uint16_t, MCU_TIMER_MHZ_LOG2), HplAtmegaCounterMicro32C;
	
	RFA1DriverLayerP.SfdCapture -> AtmegaTransformCaptureC.HplAtmegaCapture;
	AtmegaTransformCaptureC.SubCapture -> HplAtmRfa1Timer1C;
	AtmegaTransformCaptureC.HplAtmegaCounter -> HplAtmegaCounterMicro32C;
#else
	components LocalTime62khzC as LocalTimeC, new Alarm62khz32C() as AlarmC, HplAtmRfa1TimerMacC;
	RFA1DriverLayerP.SfdCapture -> HplAtmRfa1TimerMacC.SfdCapture;
#endif
	LocalTimeRadio = LocalTimeC;
	Alarm = AlarmC;
	
	RFA1DriverLayerP.LocalTime -> LocalTimeC;

#ifdef RADIO_DEBUG
	components DiagMsgC;
	RFA1DriverLayerP.DiagMsg -> DiagMsgC;
#endif

	components MainC, RealMainP;
	RealMainP.PlatformInit -> RFA1DriverLayerP.PlatformInit;
	MainC.SoftwareInit -> RFA1DriverLayerP.SoftwareInit;

	components McuSleepC;
	RFA1DriverLayerP.McuPowerState -> McuSleepC;
	RFA1DriverLayerP.McuPowerOverride <- McuSleepC;

	ExtAmpControl = RFA1DriverLayerP;
}
