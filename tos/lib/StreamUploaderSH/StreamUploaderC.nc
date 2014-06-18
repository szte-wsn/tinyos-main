/*
* Copyright (c) 2010, University of Szeged
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
* Author:Andras Biro
*/
#include "StreamUploader.h"
configuration StreamUploaderC{
	provides interface StdControl;
	provides interface Command;
}
implementation{
	components StreamUploaderP;
	components new StreamStorageClientC();
	components new AMSenderC(AM_DATA_MSG_T) as AMSend;
	components new AMReceiverC(AM_CTRL_MSG_T) as AMReceive;
	components ActiveMessageC;
	components new TimerMilliC() as WaitTimer;
	components new TimerMilliC() as StorageWaitTimer;
	components TimeSyncMessageC, NoLedsC as LedsC, LocalTimeMilliC;
	
	StreamUploaderP.Packet -> AMSend;
 	StreamUploaderP.AMPacket -> AMSend;
	StreamUploaderP.AMSend -> AMSend;
	StreamUploaderP.SplitControl -> ActiveMessageC;
	StreamUploaderP.PacketAcknowledgements -> ActiveMessageC;
	StreamUploaderP.Receive -> AMReceive;
	StreamUploaderP.WaitTimer->WaitTimer;
	StreamUploaderP.TimeSyncAMSendMilli -> TimeSyncMessageC.TimeSyncAMSendMilli[AM_CTRL_MSG_T];
	StreamUploaderP.LocalTime -> LocalTimeMilliC;
	StreamUploaderP.StreamStorageRead -> StreamStorageClientC;
	StreamUploaderP.StreamStorageErase -> StreamStorageClientC;
	StreamUploaderP.Resource -> StreamStorageClientC;
	StreamUploaderP.Leds->LedsC;
	StdControl=StreamUploaderP.StdControl;
	Command=StreamUploaderP.Command;
	
	components NoDiagMsgC as DiagMsgC;
	StreamUploaderP.DiagMsg -> DiagMsgC;
}