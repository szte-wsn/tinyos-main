COMPONENT=NullAppC
CFLAGS+=-DPLATFORM_BAUDRATE=57600UL
LDFLAGS = -Ttext=0x1E000
CFLAGS+=-DBOOTLOADER_INTERRUPTS
CFLAGS+=-fno-jump-tables
# CFLAGS+=-mrelax
CFLAGS+=-DATMEL_NO_PROGMEM

CFLAGS+=-DDISABLE_SERIAL_AUTO
CFLAGS+=-DDISABLE_SERIAL_RESET
CFLAGS+=-DDISABLE_BATTERY_CHECK
CFLAGS+=-DBOOTLOADER_INTERRUPTS

CFLAGS+=-DAVR109_HW_MAJOR=\'2\'
CFLAGS+=-DAVR109_HW_MINOR=\'1\'
include $(MAKERULES)