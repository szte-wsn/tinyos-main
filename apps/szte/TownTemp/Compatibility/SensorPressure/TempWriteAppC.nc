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
* Author: Csepe Zoltan
*/

#include <Timer.h>
#include "TempStorage.h"
#include "StorageVolumes.h"

configuration TempWriteAppC {
}
implementation {
	
	components MainC, LedsC;
	components TempWriteC as App;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components LocalTimeMilliC;
	components new LogStorageC(VOLUME_LOGTEST, TRUE);
	components new AtmegaVoltageC();
		
	components ActiveMessageC;
	  App.RadioControl -> ActiveMessageC;
	  App.Receive -> ActiveMessageC.Receive[AM_CONTROLMSG];
	  App.AMSend -> ActiveMessageC.AMSend[AM_BLINKTORADIOMSG];
	  App.Packet -> ActiveMessageC;
		App.AMPacket -> ActiveMessageC;
		App.PacketAcknowledgements -> ActiveMessageC;


	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timer0 -> Timer0;
	App.LocalTime -> LocalTimeMilliC;
	App.VoltageRead -> AtmegaVoltageC;
	App.LogWrite -> LogStorageC;
	App.LogRead-> LogStorageC;
	
	components new Sht21RawHumidityC() as HumidityC;
	components new Sht21RawTemperatureC() as TemperatureC;
	App.Temperature -> TemperatureC;
	App.Humidity -> HumidityC;
	components new PressureC();
	components new Ms5607RawTemperatureC() as MSTemperatureC;
	App.Pressure -> PressureC;
	App.MSTemperature -> MSTemperatureC;

	components ActiveMessageC as LPLProvider;
  	App.LPL -> LPLProvider;
		
	components NoDiagMsgC as DiagMsgC;
	App.DiagMsg -> DiagMsgC;

}
