// disable watchdog timer at startup (see AVR132: Using the Enhanced Watchdog Timer)
#include <avr/wdt.h> 
#if defined(BOOTLOADER_MAGIC_PTR) 
uint16_t *magic=(uint16_t*)BOOTLOADER_MAGIC_PTR;
#define platform_bootstrap() { if( *magic  == BOOTLOADER_MAGIC_VALUE) {  asm("jmp 0000");} MCUSR = 0; wdt_disable(); }
#else
#define platform_bootstrap() {MCUSR = 0; wdt_disable(); }
#endif