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
 */

#include <RadioConfig.h>
#include <TimerConfig.h>

configuration Si443xTimeSyncMessageC
{
	provides
	{
		interface SplitControl;

		interface Receive[uint8_t id];
		interface Receive as Snoop[am_id_t id];
		interface Packet;
		interface AMPacket;

		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSendRadio[am_id_t id];
		interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacketRadio;

		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;

		interface PacketTimeStamp<T62khz, uint32_t> as PacketTimeStamp62khz;
		interface TimeSyncAMSend<T62khz, uint32_t> as TimeSyncAMSend62khz[am_id_t id];
		interface TimeSyncPacket<T62khz, uint32_t> as TimeSyncPacket62khz;

		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli2;
		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli2[am_id_t id];
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli2;
	}
}

implementation
{
	components Si443xActiveMessageC, new TimeSyncMessageLayerC();

	SplitControl	= Si443xActiveMessageC;
	AMPacket	= TimeSyncMessageLayerC;
	Receive = TimeSyncMessageLayerC.Receive;
	Snoop   = TimeSyncMessageLayerC.Snoop;
	Packet  = TimeSyncMessageLayerC;

	PacketTimeStampRadio = Si443xActiveMessageC;
	TimeSyncAMSendRadio	= TimeSyncMessageLayerC;
	TimeSyncPacketRadio	= TimeSyncMessageLayerC;

	PacketTimeStampMilli	= Si443xActiveMessageC;
	TimeSyncAMSendMilli = TimeSyncMessageLayerC;
	TimeSyncPacketMilli = TimeSyncMessageLayerC;

	TimeSyncMessageLayerC.PacketTimeStampRadio -> Si443xActiveMessageC;
	TimeSyncMessageLayerC.PacketTimeStampMilli -> Si443xActiveMessageC;

	components Si443xDriverLayerC;
	TimeSyncMessageLayerC.LocalTimeRadio -> Si443xDriverLayerC;
	TimeSyncMessageLayerC.PacketTimeSyncOffset -> Si443xDriverLayerC.PacketTimeSyncOffset;

	components new TimeConverterLayerC(T62khz, RADIO_ALARM_MILLI_EXP-6) as TimeConverter62khzC, LocalTime62khzC;
	PacketTimeStamp62khz = TimeConverter62khzC;
	TimeSyncAMSend62khz = TimeConverter62khzC;
	TimeSyncPacket62khz = TimeConverter62khzC;
	TimeConverter62khzC.PacketTimeStampRadio -> Si443xActiveMessageC;
	TimeConverter62khzC.TimeSyncAMSendRadio -> TimeSyncMessageLayerC;
	TimeConverter62khzC.TimeSyncPacketRadio -> TimeSyncMessageLayerC;
	TimeConverter62khzC.LocalTimeRadio -> Si443xActiveMessageC;
	TimeConverter62khzC.LocalTimeOther -> LocalTime62khzC;

	components new TimeConverterLayerC(TMilli, RADIO_ALARM_MILLI_EXP) as TimeConverterMilliC, LocalTimeMilliC;
	PacketTimeStampMilli2 = TimeConverterMilliC;
	TimeSyncAMSendMilli2 = TimeConverterMilliC;
	TimeSyncPacketMilli2 = TimeConverterMilliC;
	TimeConverterMilliC.PacketTimeStampRadio -> Si443xActiveMessageC;
	TimeConverterMilliC.TimeSyncAMSendRadio -> TimeSyncMessageLayerC;
	TimeConverterMilliC.TimeSyncPacketRadio -> TimeSyncMessageLayerC;
	TimeConverterMilliC.LocalTimeRadio -> Si443xActiveMessageC;
	TimeConverterMilliC.LocalTimeOther -> LocalTimeMilliC;
}
