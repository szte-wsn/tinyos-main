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

generic module AtmegaTransformCaptureC(typedef to_size_t @integer(), typedef from_size_t @integer(), int bitshift)
{
	provides interface HplAtmegaCapture<to_size_t>;
	uses interface HplAtmegaCapture<from_size_t> as SubCapture;
	uses interface HplAtmegaCounter<to_size_t>;
}
implementation{
	enum
	{
		FROM_SIZE = sizeof(from_size_t),
		TO_SIZE = sizeof(to_size_t),
		BITSHIFT = bitshift,
		MASK = (1UL << (FROM_SIZE * 8 - BITSHIFT)) - 1,
	};
	
	to_size_t captured;
	
	async command to_size_t HplAtmegaCapture.get(){
		return captured;
	}
	
	async command void HplAtmegaCapture.set(to_size_t value){
		captured = value;
	}
	
	inline void convert(){
		from_size_t from = call SubCapture.get();
		captured = call HplAtmegaCounter.get();
		captured -= ((from_size_t)captured - (from >> BITSHIFT)) & MASK;
	}

	async event void SubCapture.fired(){
		convert();
		signal HplAtmegaCapture.fired();
	}

	async command bool HplAtmegaCapture.test(){
		if ( call SubCapture.test() ){
			convert();
			return TRUE;
		} else
			return FALSE;
	}

	async command void HplAtmegaCapture.reset(){
		call SubCapture.reset();
	}

	async command void HplAtmegaCapture.start(){
		call SubCapture.start();
	}

	async command void HplAtmegaCapture.stop(){
		call SubCapture.stop();
	}

	async command bool HplAtmegaCapture.isOn(){
		return call SubCapture.isOn();
	}

	async command void HplAtmegaCapture.setMode(uint8_t mode){
		call SubCapture.setMode(mode);
	}

	async command uint8_t HplAtmegaCapture.getMode(){
		return call SubCapture.getMode();
	}
	
	async event void HplAtmegaCounter.overflow(){}
}