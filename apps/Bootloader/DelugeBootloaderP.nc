#include <Deluge.h>
#include <DelugePageTransfer.h>
#include "TOSBoot_platform.h"
#include "crc.h"
module DelugeBootloaderP{
  uses interface InternalFlash as IntFlash;  
  uses interface ExtFlash;
  uses interface AtmelBootloader;
  provides interface BootloaderInterface;
  
//   uses interface StdControl;
//   uses interface UartByte;
}
implementation{
  enum{
    INACTIVE = 0,
    ACTIVE = 1,
    DONE = 2,
    FAILED = 3,
  };
  uint8_t  buf[TOSBOOT_INT_PAGE_SIZE];
  norace uint32_t externalAddress;
  norace uint32_t sectorRemains;
  norace uint32_t internalAddress;
  norace uint8_t programming = INACTIVE;
  
  task void writeNextPage();
  
  async command error_t BootloaderInterface.stop(){
//     call AtmelBootloader.enableFlash();
//     post bootloaderStop();
    //TODO
    return SUCCESS;
  }
  
  async command void BootloaderInterface.startMainProgram(){
    call BootloaderInterface.stop();
    signal BootloaderInterface.exitBootloader(programming==DONE);
  }
  
  
  async command void BootloaderInterface.exitBootloaderReady(){
    call AtmelBootloader.exitBootloader();
  }
  
  
  bool verifyBlock(uint32_t crcAddr, uint32_t startAddr, uint16_t len)
  {
    uint16_t crcTarget, crcTmp;
    
    // read crc
    call ExtFlash.startRead(crcAddr);
    crcTarget = (uint16_t)(call ExtFlash.readByte() & 0xff) << 8;
    crcTarget |= (uint16_t)(call ExtFlash.readByte() & 0xff);
    call ExtFlash.stopRead();
    
    
    // compute crc
    call ExtFlash.startRead(startAddr);
    for ( crcTmp = 0; len; len-- ){
      crcTmp = crcByte(crcTmp, call ExtFlash.readByte());
    }
    call ExtFlash.stopRead();
    
    return crcTarget == crcTmp;
  }
  
  bool verifyImage(uint32_t startAddr) {
    uint32_t addr;
    uint8_t  numPgs;
    uint8_t  i;
    uint8_t buffer[16];
    
    call ExtFlash.startRead(startAddr);
    
    for(i=0;i<16;i++)
      buffer[i] = call ExtFlash.readByte();
    call ExtFlash.stopRead();
    
    //check the first block
    if (!verifyBlock(startAddr + offsetof(DelugeIdent,crc), startAddr, offsetof(DelugeIdent,crc)))
      return FALSE;
    
    // read size of image
    call ExtFlash.startRead(startAddr + offsetof(DelugeIdent,numPgs));
    numPgs = call ExtFlash.readByte();
    call ExtFlash.stopRead();
    
    
    if (numPgs == 0 || numPgs == 0xff)
      return FALSE;
    startAddr += DELUGE_IDENT_SIZE;
    addr = DELUGE_CRC_BLOCK_SIZE;
    
    for ( i = 0; i < numPgs; i++ ) {
      if (!verifyBlock(startAddr + i*sizeof(uint16_t), startAddr + addr, DELUGE_BYTES_PER_PAGE)) {
        return FALSE;
      }
      addr += DELUGE_BYTES_PER_PAGE;
    }
    return TRUE;
  }
  
  uint32_t extFlashReadUint32() {
    uint32_t result = 0;
    int8_t  i;
    for ( i = 3; i >= 0; i-- )
      result |= (uint32_t)call ExtFlash.readByte() << (i*8);
    return result;
  }
  
  async command error_t BootloaderInterface.start(){
    BootArgs args;
    uint32_t baseAddress;
//     call StdControl.start();
    call IntFlash.read((uint8_t*)TOSBOOT_ARGS_ADDR, &args, sizeof(args));
    if ( !args.noReprogram ) {
      baseAddress = args.imageAddr;
      if( !verifyImage(baseAddress) )
         return FAIL;
      
      externalAddress = baseAddress + DELUGE_IDENT_SIZE + DELUGE_CRC_BLOCK_SIZE;
      
      call ExtFlash.startRead(externalAddress);
      
      internalAddress = extFlashReadUint32();
      sectorRemains = extFlashReadUint32();
      externalAddress += 8;
      call ExtFlash.stopRead();
      
      if ( sectorRemains == 0xffffffff || internalAddress != 0 ){  //the first internal address is different on other platforms! MSP430: TOSBOOT_END, Mulle: 0xA0000
        return FAIL;
      }
      post writeNextPage();
      programming = ACTIVE;
      return SUCCESS;
    }
    return EOFF;
  }
  
  async event void AtmelBootloader.erasePageDone(){
    if( programming == ACTIVE) {
      signal BootloaderInterface.write(internalAddress);
      if( call AtmelBootloader.writePage(internalAddress, buf) != SUCCESS ){
        programming = FAILED;
        signal BootloaderInterface.exitBootloader(programming==DONE);
      }
    }
  }
  
  async event void AtmelBootloader.writePageDone(){
    if( programming == ACTIVE) {
      internalAddress+=call AtmelBootloader.getPageSize();
      post writeNextPage();
    }
  }
  
  task void writeNextPage(){
    if( sectorRemains > 0){
      uint16_t internalOffset = 0;
      call ExtFlash.startRead(externalAddress);
      // fill in ram buffer for internal program flash sector
      while( sectorRemains>0 && internalOffset<call AtmelBootloader.getPageSize() ){
        buf[internalOffset] = call ExtFlash.readByte();
        internalOffset++; externalAddress++;
        if ( --sectorRemains == 0 ) {
          uint32_t currentIntAddr = extFlashReadUint32();
          sectorRemains = extFlashReadUint32();
          externalAddress = externalAddress + 8;
          if(sectorRemains == 0xffffffff || currentIntAddr != internalAddress+internalOffset){
            call ExtFlash.stopRead();
            programming = FAILED;
            signal BootloaderInterface.exitBootloader(programming==DONE);
          }
        }
      }
      call ExtFlash.stopRead();
      signal BootloaderInterface.erase(internalAddress);
      if( call AtmelBootloader.erasePage(internalAddress) != SUCCESS ) {
        programming = FAILED;
        signal BootloaderInterface.exitBootloader(programming==DONE);
      }
    } else {
      programming = DONE;
      call AtmelBootloader.enableFlash();
      signal BootloaderInterface.exitBootloader(programming==DONE);
    }
  }
}