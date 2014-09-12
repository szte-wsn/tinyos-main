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
  uses interface Alarm<TMicro, uint32_t>;
  uses interface Leds;
  uses interface BootloaderInterface;
  uses interface BootloaderInterface as DelugeInterface;
  uses interface BusyWait<TMicro, uint16_t>;
  provides interface McuPowerOverride;
  uses interface McuPowerState;
}
implementation
{
  enum{
    LEDCOUNT = 4,
    BOOTLOADER_TIMEOUT = 3000000UL,
  };
  norace int8_t ledCounter = LEDCOUNT;
  
  norace uint8_t exiting = 0;
  
  event void Boot.booted() {
    call McuPowerState.update();
    if( call DelugeInterface.start() != SUCCESS ){
      call Leds.set((1<<ledCounter) - 1);
      call Alarm.start(BOOTLOADER_TIMEOUT/LEDCOUNT);
      call BootloaderInterface.start();
    }
  }
  
  async event void Alarm.fired(){
    if( exiting == 0 ){
      if( --ledCounter >= 0 ){
        call Leds.set((1<<ledCounter) - 1);
        call Alarm.start(BOOTLOADER_TIMEOUT/LEDCOUNT);
      } else {
        call BootloaderInterface.startMainProgram();
      }
    } else {
      if( --exiting == 1 ){
        call Leds.set(0);
        call Alarm.stop();
        //HACK The uart and this alarm uses a counter, but it's impossible to stop a counter through the Counter interface
        CLR_BIT(TIMSK1, TOIE1);
        CLR_BIT(TIMSK3, TOIE3);
        call BootloaderInterface.exitBootloaderReady();
      } else {
        call Alarm.start(100000UL);
        if(call Leds.get() == 0)
          call Leds.set(0xff);
        else
          call Leds.set(0);
      }
    }
  }
  
  async event void BootloaderInterface.contacted(){
    call Alarm.stop();
  }
  
  async event void BootloaderInterface.erase(uint32_t address){
    call Leds.set(0);
    call Leds.led0On();
    call Leds.led3Toggle();
  }
  
  async event void BootloaderInterface.read(uint32_t address){
    call Leds.set(0);
    call Leds.led1On();
    call Leds.led3Toggle();
  }
  
  async event void BootloaderInterface.write(uint32_t address){
    call Leds.set(0);
    call Leds.led2On();
    call Leds.led3Toggle();
  }
  
  async event void DelugeInterface.erase(uint32_t address){
    call Leds.set(0);
    call Leds.led0On();
    call Leds.led3Toggle();
  }
  
  async event void DelugeInterface.read(uint32_t address){
    call Leds.set(0);
    call Leds.led1On();
    call Leds.led3Toggle();
  }
  
  async event void DelugeInterface.write(uint32_t address){
    call Leds.set(0);
    call Leds.led2On();
    call Leds.led3Toggle();
  }
  
  task void startTimer(){
    exiting = 7;//three blinking
    call Leds.set(0xff);
    call Alarm.start(100000UL);
  }
  
  async event void BootloaderInterface.exitBootloader(bool programmingSuccessful){
    post startTimer();
  }
  
  async event void DelugeInterface.exitBootloader(bool programmingSuccessful){
    if( programmingSuccessful ){
      post startTimer();
    } else {
      call Leds.set((1<<ledCounter) - 1);
      call Alarm.start(BOOTLOADER_TIMEOUT/LEDCOUNT);
      call BootloaderInterface.start();
    }
  }
  
  async command mcu_power_t McuPowerOverride.lowestState() {
    return ATM128_POWER_IDLE; //somehow the sleep mode doesn't work in the bootloader
  }
  
  async event void DelugeInterface.contacted(){}
}

