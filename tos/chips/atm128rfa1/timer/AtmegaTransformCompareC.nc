/*
 * Copyright (c) 2015, University of Szeged
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
 * Author: Andras Biro
 */

generic module AtmegaTransformCompareC(typedef to_size_t @integer(), typedef from_size_t @integer(), int bitshift)
{
	provides interface HplAtmegaCompare<to_size_t>;
	uses interface HplAtmegaCompare<from_size_t> as SubCompare;
	uses interface HplAtmegaCounter<to_size_t>;
	
	uses interface DiagMsg;
}
implementation{
	to_size_t compareValue;
	bool willFire;
	
	enum{
		FROM_SIZE = sizeof(from_size_t),
		MAX_COMPARE_FROM = (1UL<<(8*FROM_SIZE)) - (1<<bitshift),
		MAX_COMPARE_TO = (1UL<<(8*FROM_SIZE-bitshift))-1,
	};
	
	async command to_size_t HplAtmegaCompare.get(){
		return compareValue;
	}

	async command void HplAtmegaCompare.set(to_size_t value){
		compareValue = value;
	}
	
	inline void startSubCompare(){
		if( (to_size_t)(compareValue - call HplAtmegaCounter.get()) > MAX_COMPARE_TO ){
			willFire = FALSE;
			call SubCompare.set((call HplAtmegaCounter.get() << bitshift) + MAX_COMPARE_FROM );
		} else {
			willFire = TRUE;
			call SubCompare.set((from_size_t)(compareValue << bitshift));
		}
		call SubCompare.start();
	}
	
	async command void HplAtmegaCompare.start(){
		startSubCompare();
	}
	
	async event void SubCompare.fired(){
		atomic {
			if(willFire){
				signal HplAtmegaCompare.fired();
			} else {
				startSubCompare();
			}
		}
	}

	async command void HplAtmegaCompare.stop(){
		call SubCompare.stop();
	}

	async command bool HplAtmegaCompare.isOn(){
		return call SubCompare.isOn();
	}

	async command void HplAtmegaCompare.setMode(uint8_t mode){
		call SubCompare.setMode(mode);
	}

	async command uint8_t HplAtmegaCompare.getMode(){
		return call SubCompare.getMode();
	}

	async command bool HplAtmegaCompare.test(){
		return willFire && call SubCompare.test();
	}

	async command void HplAtmegaCompare.reset(){
		if( willFire )
			call SubCompare.reset();
	}

	async command void HplAtmegaCompare.force(){
		willFire = TRUE;
		call SubCompare.force();
	}
	
	async event void HplAtmegaCounter.overflow(){}
}