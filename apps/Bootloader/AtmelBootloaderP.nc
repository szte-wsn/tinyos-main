#include <avr/boot.h>
#include <avr/pgmspace.h>

module AtmelBootloaderP{
  provides interface AtmelBootloader;
}
implementation{
  enum{
    S_IDLE,
    S_ERASE,
    S_WRITE,
    S_READ,
  };
  
  norace uint8_t state = S_IDLE;
  uint32_t currentAddress;
  
  async command uint16_t AtmelBootloader.getPageSize(){
    return SPM_PAGESIZE;
  }
  
  async command uint32_t AtmelBootloader.getFlashSize(){
    return FLASHEND;
  }
  
  async command uint32_t AtmelBootloader.getBootloaderStart(){
    switch( ((boot_lock_fuse_bits_get(GET_HIGH_FUSE_BITS) & 0x6)>>1) ){ //TODO this is ugly, but there's no libc support for reading the bootloader size. But is this platform independent?
      case 0:{
        return FLASHEND-8192U;
      }break;
      case 1:{
        return FLASHEND-4096U;
      }break;
      case 2:{
        return FLASHEND-2048U;
      }break;
      case 3:{
        return FLASHEND-1024U;
      }break;
      default:{
        return FLASHEND;
      }break;
    }
  }
  
  async command error_t AtmelBootloader.disableFlash(){
    return SUCCESS;
  }
  
  async command error_t AtmelBootloader.enableFlash(){
    if( state != S_IDLE )
      return EBUSY; //we could return EALREADY also, but we're saving some space
    boot_rww_enable();
    return SUCCESS;
  }
  
  async command error_t AtmelBootloader.erasePage(uint32_t address){
    if( state != S_IDLE )
      return EBUSY;
    
    state = S_ERASE;
    atomic{
      boot_page_erase(address);
      boot_spm_interrupt_enable();
    }
    return SUCCESS;
  }
  
  async command error_t AtmelBootloader.writePage(uint32_t address, void* data){
    if( address > call AtmelBootloader.getBootloaderStart() )
      return EINVAL;
    if( state != S_IDLE )
      return EBUSY;

    state = S_WRITE;
    for(currentAddress = 0; currentAddress < SPM_PAGESIZE; currentAddress+=2){
      uint16_t wdata =  *((uint8_t*)data+currentAddress);
      wdata |= (*((uint8_t*)data+currentAddress+1))<<8;
      boot_page_fill(address + currentAddress, wdata);
    }
    atomic{
      boot_page_write(address);
      boot_spm_interrupt_enable();
    }
    return SUCCESS;
  }
  
  async command error_t AtmelBootloader.readPage(uint32_t address, void* data){
    if( address >= FLASHEND )
      return EINVAL;
    if( state != S_IDLE )
      return EBUSY;
    
    state = S_READ;
    for(currentAddress = 0; currentAddress < SPM_PAGESIZE; currentAddress++){
      *((uint8_t*)data+currentAddress) = pgm_read_byte_far(address + currentAddress);
    }
    state = S_IDLE;
    return SUCCESS;
  }
  
  async command void AtmelBootloader.exitBootloader(){
		atomic{
			uint8_t temp = MCUCR;
			MCUCR = temp | (1<<IVCE);
			MCUCR = temp & ~(1<<IVSEL);
      asm("jmp 0000");
		}    
  }
  
  AVR_ATOMIC_HANDLER(SPM_READY_vect){
    uint8_t prevState = state;
    boot_spm_interrupt_disable();
    state = S_IDLE;
    switch(prevState){
      case S_ERASE:{
        signal AtmelBootloader.erasePageDone();
      }break;
      case S_WRITE:{
        signal AtmelBootloader.writePageDone();
      }break;
    }
  }
}