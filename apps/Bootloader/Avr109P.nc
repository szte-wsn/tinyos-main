/*
* Copyright (c) 2012, Unicomp Kft.
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
* Author: Andras Biro <bbandi86@gmail.com>
*/

module Avr109P{
  uses interface UartStream;
  uses interface UartByte;
  uses interface StdControl;
  uses interface AtmelBootloader;
  provides interface BootloaderInterface;
}
implementation{
  #ifndef AVR109_HW_MAJOR
  #define AVR109_HW_MAJOR '1'
  #endif
  #ifndef AVR109_HW_MINOR
  #define AVR109_HW_MINOR '0'
  #endif
  
  uint32_t address, eraseAddress;
  uint8_t buf[SPM_PAGESIZE];
  bool busy = FALSE;
  bool contacted = FALSE;
  bool exitSuccess = FALSE;

  
  task void bootloaderStart(){
    call StdControl.start();
    call UartStream.enableReceiveInterrupt();
    call UartByte.send('?'); //workaround: if avrdude is connected before the bootloader starts, it won't connect, unless we send something to it
  }
  
  //TODO this task doesn't seems to run
  task void bootloaderStop(){
    call StdControl.stop();
  }

  async command error_t BootloaderInterface.start(){
    post bootloaderStart();
    return SUCCESS;
  }
  
  async command error_t BootloaderInterface.stop(){
    call AtmelBootloader.enableFlash();
    call UartStream.disableReceiveInterrupt();
    post bootloaderStop();
    return SUCCESS;
  }
  
  async command void BootloaderInterface.startMainProgram(){
    call AtmelBootloader.enableFlash();
    call UartStream.disableReceiveInterrupt();
    post bootloaderStop();
    signal BootloaderInterface.exitBootloader(exitSuccess);
  }
  
  
  async command void BootloaderInterface.exitBootloaderReady(){
    call AtmelBootloader.exitBootloader();
  }

  async event void UartStream.receivedByte( uint8_t byte ){
    if(!busy){
      call UartStream.disableReceiveInterrupt();
      switch(byte){
        case 'a':{//auto increment address
          buf[0]='Y';
          call UartStream.send(buf,1);
        }break;
        case 'A':{//set address
          uint8_t tmp;
          call UartByte.receive(&tmp,255);
          address = tmp<<8;
          call UartByte.receive(&tmp,255);
          address += tmp;
          buf[0]='\r';
          call UartStream.send(buf,1);
          address<<=1;
          address &= call AtmelBootloader.getFlashSize(); //cut unwanted sign bits
        }break;
  #define REMOVE_FLASH_BYTE_SUPPORT
  #ifndef REMOVE_FLASH_BYTE_SUPPORT
        case 'c':{//write program memory, low byte
        }break;
        case 'C':{//write program memory, high byte
        }break;
        case 'm':{//issue page page write
        }break;
        case 'R':{//read program memory
        }break;
  #endif
  #define REMOVE_EEPROM_BYTE_SUPPORT
  #ifndef REMOVE_EEPROM_BYTE_SUPPORT
        case 'd':{//read data memory
        }break;
        case 'D':{//write data memory
        }break;
  #endif
        case 'e':{//chip erase
          busy = TRUE;
          eraseAddress = 0;
          signal BootloaderInterface.erase(eraseAddress);
          call AtmelBootloader.erasePage(eraseAddress);
        }break;
//   #define REMOVE_FUSE_AND_LOCK_BIT_SUPPORT
  #ifndef REMOVE_FUSE_AND_LOCK_BIT_SUPPORT
        case 'l':{//write lock bits
          uint8_t tmp;
          call UartByte.receive(&tmp,255);
          call AtmelBootloader.setLockBits(tmp);
          buf[0]='\r';
          call UartStream.send(buf,1);
        }break;
        case 'r':{//read lock bits
          buf[0] = call AtmelBootloader.getLockBits();
          call UartStream.send(buf,1);
        }break;
        case 'F':{//read (low) fuse bits
          buf[0] = call AtmelBootloader.getLowFuseBits();
          call UartStream.send(buf,1);
        }break;
        case 'N':{//read high fuse bits
          buf[0] = call AtmelBootloader.getHighFuseBits();
          call UartStream.send(buf,1);
        }break;
        case 'Q':{//read extended fuse bits
          buf[0] = call AtmelBootloader.getExtendedFuseBits();
          call UartStream.send(buf,1);
        }break;
  #endif /*REMOVE_FUSE_AND_LOCK_BIT_SUPPORT*/
  //#define REMOVE_AVRPROG_SUPPORT
  #ifndef REMOVE_AVRPROG_SUPPORT
        case 'P'://enter programming mode
        case 'L':{//leave programming mode
          buf[0]='\r';//we're in programming mode while we're in the bootloader
          call UartStream.send(buf,1);
        }break;
        case 'E':{//exit bootloader
          busy = TRUE;
          buf[0]='\r';//we're in programming mode while we're in the bootloader
          call UartStream.send(buf,1);
          exitSuccess = TRUE;
          call BootloaderInterface.startMainProgram();
        }break;
        case 'p':{//return programmer type
          buf[0]='S';
          call UartStream.send(buf,1);
        }break;
        case 't':{//return supported device codes - unsupported, just following the protocol
          buf[0]=1;
          buf[1]=0;
          call UartStream.send(buf,2);
        }break;
        //unsupported stuff
        case 'x'://set led  
        case 'y'://clear led
        case 'T':{//select device type
          call UartByte.receive(buf,255);
          buf[0]='\r';
          call UartStream.send(buf,1);
        }break;
  #endif
  // #define REMOVE_BLOCK_SUPPORT
  #ifndef REMOVE_BLOCK_SUPPORT
        case 'b':{//check block support
          buf[0] = 'Y';
          buf[1] = (call AtmelBootloader.getPageSize() >> 8);
          buf[2] = (call AtmelBootloader.getPageSize() & 0xff);
          call UartStream.send(buf,3);
        }break;
        case 'B':{//start block flash/eeprom load
          uint16_t bs;
          uint8_t tmp;
          char memtype;
          busy = TRUE;
          call UartByte.receive(&tmp, 255);
          bs = tmp<<8;
          call UartByte.receive(&tmp, 255);
          bs += tmp;
          call UartByte.receive((uint8_t*)(&memtype), 255);
          if( memtype == 'F' ){
            if( bs != call AtmelBootloader.getPageSize() ){
              buf[0] = '?';
              busy = FALSE;
              call UartStream.send(buf, 1);
            } else {
              call UartStream.receive(buf, bs);
              return;//don't reenable the interrupt
              //blocking read, if something's wrong with split-phase
//               uint16_t i;
//               for(i = 0; i<256; i++){
//                 call UartByte.receive((uint8_t*)(buf+i), 255);
//               }
//               signal BootloaderInterface.write(address);
//               call AtmelBootloader.writePage(address, (void*)(buf));
            }
          } else if( memtype == 'E'){
            //TODO
            buf[0] = '?';
            busy = FALSE;
            call UartStream.send(buf, 1);
          } else {
            buf[0] = '?';
            busy = FALSE;
            call UartStream.send(buf, 1);
          }
        }break;
        case 'g':{//start block flash/eeprom read
          uint16_t bs;
          uint8_t tmp;
          char memtype;
          call UartByte.receive(&tmp, 255);
          bs = tmp<<8;
          call UartByte.receive(&tmp, 255);
          bs += tmp;
          call UartByte.receive((uint8_t*)(&memtype), 255);
          signal BootloaderInterface.read(address);
          if( memtype == 'F' ){ //FLASH
            if( bs == call AtmelBootloader.getPageSize() ){
              call AtmelBootloader.readPage(address, buf);
              address+=call AtmelBootloader.getPageSize();
              call UartStream.send(buf, bs);
            }
          } else { //'E' EEPROM
            //TODO
          }
          
        }break;
  #endif
        case 's':{//read signature bytes
          buf[0]=SIGNATURE_2;
          buf[1]=SIGNATURE_1;
          buf[2]=SIGNATURE_0;
          call UartStream.send(buf,3);
        }break;
        case 'S':{//return software identifier
          buf[0]='T';
          buf[1]='O';
          buf[2]='S';
          buf[3]='B';
          buf[4]='O';
          buf[5]='O';
          buf[6]='T';
          call UartStream.send( buf, 7 );
        }
        case 'V':{//return software version
          buf[0]='2';
          buf[1]='0';
          call UartStream.send(buf,2);
        }break;
        case 'v':{//return hw version;
          buf[0]=AVR109_HW_MAJOR;
          buf[1]=AVR109_HW_MINOR;
          call UartStream.send(buf,2);
        }break;
//         case 'q':{
//           buf[0] = address;
//           buf[1] = address>>8;
//           buf[2] = address>>16;
//           buf[3] = address>>24;
//           call UartStream.send(buf,4);
//         }break;
        default:{//unknown command
          buf[0]='?';
          call UartStream.send(buf,1);
        }
      }
      if( !contacted && buf[0] != '?' ){
        contacted = TRUE;
        signal BootloaderInterface.contacted();
      }
      call UartStream.enableReceiveInterrupt();
    }
  }
  
  void done(){
    busy = FALSE;
    call UartStream.send(buf, 1);
  }

  async event void UartStream.receiveDone(uint8_t* buffer, uint16_t len, error_t error ){
    if( call AtmelBootloader.writePage(address, (void*)(buf)) != SUCCESS ){
      buffer[0]='?';
      call UartStream.enableReceiveInterrupt();
      done();
    }
  }
    
  async event void AtmelBootloader.writePageDone(){
    if( contacted ) {
      call UartStream.enableReceiveInterrupt();
      call AtmelBootloader.enableFlash();
      signal BootloaderInterface.write(address);
      address+=call AtmelBootloader.getPageSize();
      buf[0]='\r';
      done();
    }
  }
  
  async event void AtmelBootloader.erasePageDone(){
    if( contacted ) {
      signal BootloaderInterface.erase(eraseAddress);
      eraseAddress += call AtmelBootloader.getPageSize();
      if( eraseAddress < call AtmelBootloader.getBootloaderStart() ){
        call AtmelBootloader.erasePage(eraseAddress);
      } else {
        call AtmelBootloader.enableFlash();
        buf[0]='\r';
        done();
      }
    }
  }
  
  async event void UartStream.sendDone( uint8_t* buffer, uint16_t len, error_t error ){}
  
  default async event void BootloaderInterface.erase(uint32_t addr){}
  default async event void BootloaderInterface.read(uint32_t addr){}
  default async event void BootloaderInterface.write(uint32_t addr){}
  default async event void BootloaderInterface.exitBootloader(bool exitSucc){}
}