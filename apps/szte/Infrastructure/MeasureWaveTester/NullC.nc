/*
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 * - Neither the name of the University of California nor the names of
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
/*
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Null is an empty skeleton application.  It is useful to test that the
 * build environment is functional in its most minimal sense, i.e., you
 * can correctly compile an application. It is also useful to test the
 * minimum power consumption of a node when it has absolutely no 
 * interrupts or resources active.
 *
 * @author Cory Sharp <cssharp@eecs.berkeley.edu>
 * @date February 4, 2006
 */
module NullC @safe()
{
  uses interface Boot;
	uses interface MeasureWave;
	uses interface DiagMsg;
	uses interface LocalTime<TMicro>;
}
implementation
{
	// szep/01871_01007.raw
	uint8_t samples[] = {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 15, 16, 16, 15, 14, 13, 14, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 14, 14, 13, 13, 14, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 15, 14, 13, 13, 13, 14, 14, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 14, 13, 13, 14, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 14, 14, 13, 13, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 15, 14, 13, 13, 13, 14, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 13, 13, 13, 13, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 13, 13, 13, 14, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 15, 15, 14, 13, 13, 13, 14, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 14, 13, 13, 13, 14, 14, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 13, 13, 13, 14, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 14, 13, 13, 14, 14, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 14, 14, 13, 13, 14, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 14, 13, 13, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 14, 13, 13, 14, 14, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 14, 14, 13, 13, 13, 14, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 14, 14, 13, 13, 14, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 14, 13, 13, 14, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 14, 13, 13, 14, 14, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 13, 13, 13, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 14, 13, 13, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 15, 15, 14, 13, 13, 13, 14, 14, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 15, 15, 15, 14, 13, 13, 13, 13, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 15};
	
  event void Boot.booted() {
		uint32_t time;
    atomic{
			time = call LocalTime.get();
			call MeasureWave.changeData(samples, sizeof(samples));
			time = call LocalTime.get() - time;
		}
		if( call DiagMsg.record() ){
			call DiagMsg.uint8( call MeasureWave.getPeriod());
			call DiagMsg.uint8( call MeasureWave.getPhase());
			call DiagMsg.uint32( time );
			call DiagMsg.send();
		}
  }
}

