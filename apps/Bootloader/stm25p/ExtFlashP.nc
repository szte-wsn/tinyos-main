// $Id: ExtFlashP.nc,v 1.2 2010-06-29 22:07:50 scipio Exp $

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
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

module ExtFlashP {
  provides {
    interface Init;
    interface ExtFlash;
  }
  uses {
    interface Resource;
    interface SpiByte;
    interface GeneralIO as CSN;
    interface GeneralIO as Hold;
    interface GeneralIO as Power;
    interface BusyWait<TMicro, uint16_t>;
  }
}

implementation {

  enum{
    DUMMY = unique("Stm25pOn"),
  };
  
  command error_t Init.init() {
    call Power.makeOutput();
    #if !defined(UCMINI_REV) || (UCMINI_REV > 101)
      call Power.set();
    #else
      call Power.clr();
    #endif
    #if ( defined(PLATFORM_UCMINI) && (UCMINI_REV>100 || !defined(UCMINI_REV)) )
    call BusyWait.wait(60000U);
    #endif
    call Hold.makeOutput();
    call Hold.set();
    call CSN.makeOutput();
    call CSN.set();
    call Resource.immediateRequest();
    return SUCCESS;
  }

  void powerOnFlash() {

    uint8_t i;

    call CSN.clr();

    // command byte + 3 dummy bytes + signature
    for ( i = 0; i < 5; i++ ) {
      call SpiByte.write(0xab);
    }
    
    call CSN.set();

  }

  async command void ExtFlash.startRead(uint32_t addr) {

    uint8_t i;
    
    powerOnFlash();
    
    call CSN.clr();
    
    // add command byte to address
    addr |= (uint32_t)0x3 << 24;
    
    // address
    for ( i = 4; i > 0; i-- ) {
      call SpiByte.write((addr >> (i-1)*8) & 0xff);
    }    

  }

  async command uint8_t ExtFlash.readByte() {
    return call SpiByte.write(0);
  }

  async command void ExtFlash.stopRead() {
    call CSN.set();
  }
  
  event void Resource.granted(){}
}
