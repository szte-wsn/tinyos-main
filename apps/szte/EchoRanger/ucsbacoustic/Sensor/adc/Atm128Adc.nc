/*
* Copyright (c) 2009, University of Szeged
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

interface Atm128Adc
{
	/**
	 * Sets the parameters of the next ADC conversion. If you update the
	 * source parameters while countinuous sampling, then the change will not
	 * take effect immediatelly.
	 *
	 * @param channel A/D conversion channel.
	 * @param refVoltage Select reference voltage for A/D conversion. See
	 *   the ATM128_ADC_VREF_xxx constants in Atm128ADC.h
	 * @param leftJustify TRUE to place A/D result in high-order bits 
	 *   (i.e., shifted left by 6 bits), FALSE to place it in the low-order bits
	 * @return TRUE if the conversion will be precise, FALSE if it will be 
	 *   imprecise (due to a change in refernce voltage, or switching to a
	 *   differential input channel)
	 */
	async command bool setSource(uint8_t channel, uint8_t refVoltage, bool leftJustify);

	/**
	 * Initiates the sampling of the selected ADC channel.
	 *
	 * @param prescaler Prescaler value for the A/D conversion clock. If you 
	 *  specify ATM128_ADC_PRESCALE, a prescaler will be chosen that guarantees
	 *  full precision. Other prescalers can be used to get faster conversions. 
	 *  See the ATmega128 manual and Atm128ADC.h for details.
	 * @param multiple If set, then the ADC channel is sampled continuously 
	 *  until the <code>cancel</code> command is called.
	 */
	async command void getData(uint8_t prescaler, uint8_t trackHoldTime, bool multiple);

	/**
	 * Signaled for each sample. You may call <code>cancel</code> to
	 * stop countinuous sampling, or update the channel with the
	 * <code>setCource</code> command. Note, that all interrupts are disabled
	 * while executing this event, and you should not do any processing here.
	 *
	 * @param data a 2 byte unsigned data value sampled by the ADC.
	 */
	async event void dataReady(uint16_t data);

	/**
	 * Cancel an outstanding getData operation. Use with care, to
	 * avoid problems with races between the dataReady event and cancel.
	 * When this command returns, the dataReady event will not be signalled,
	 * (but it could be signalled while this command is executing).
	 */
	async command void cancel();
}
