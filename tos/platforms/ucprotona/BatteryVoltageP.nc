/* Copyright (c) 2007 Johns Hopkins University.
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
 * - Neither the name of the copyright holders nor the names of
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
 */
/**
 * Battery Voltage. The returned value represents the difference
 * between the battery voltage and V_BG (1.23V). The formula to convert
 * it to mV is: 1223 * 1024 / value.
 *
 * @author Razvan Musaloiu-E.
 */
module BatteryVoltageP
{
  provides interface Atm128AdcConfig;
  provides interface Read<uint16_t> as VoltageMilliVolts;
  
  uses interface Read<uint16_t> as AdcRaw;
  uses interface GeneralIO as MeasureBridge;
}
implementation
{
	uint16_t rawAdc;
	uint16_t milliVolts;
	error_t err;
	
	task void calcTask();
	
	command error_t VoltageMilliVolts.read()
	{
		return call AdcRaw.read();
	}

	async command uint8_t Atm128AdcConfig.getChannel()
	{
	    return  ATM128_ADC_SNGL_1_23;
	}
	
	async command uint8_t Atm128AdcConfig.getRefVoltage()
	{
	    return ATM128_ADC_VREF_AVCC;
	}
	
	async command uint8_t Atm128AdcConfig.getPrescaler()
	{
	    return ATM128_ADC_PRESCALE;
	}

	event void AdcRaw.readDone(error_t result, uint16_t val)
	{
		err = result;
		
		rawAdc = val;
		post calcTask();
	}
	
	task void calcTask()
	{
	  /**
	  * Battery Voltage. The returned value represents the difference
	  * between the battery voltage and V_BG (1.23V). The formula to convert
	  * it to mV is: 1223 * 1024 / value.
	  *
	  * @author Razvan Musaloiu-E.
	  */
		uint16_t rv = 1200;
		uint16_t fs = 1024;
		uint32_t temp = 0;
		if(err == SUCCESS) 
		{
			temp = (uint32_t)rv * (uint32_t)fs;
			temp /= (uint32_t)rawAdc;
			
			milliVolts = (uint16_t)temp;
		}
		else milliVolts = 0;
		
		signal VoltageMilliVolts.readDone(err, milliVolts);
	}
}