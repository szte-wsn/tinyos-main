COMPONENT=TestAlarmC
TOSMAKE_PRE_EXE_DEPS += Send.class Receive.class
TOSMAKE_CLEAN_EXTRA = *.class RssiMsg.java CommandMsg.java RssiDoneMsg.java
# BOOTLOADER=tosboot
include ../Makecommon

CFLAGS += -DCONTINOUS_WAVE
CFLAGS += -I$(TOSDIR)/lib/diagmsg
#for the mini 2
CFLAGS+=-DDISABLE_BATTERY_CHECK
#for the mini 1
CFLAGS += -DUCMINI_REV=101

# CFLAGS += -DDIAGMSG_RADIO
# CFLAGS += -DRADIO_DEBUG
# CFLAGS += -DDIAGMSG_RECORDED_MSGS=60
# CFLAGS += -DDIAGMSG_SERIAL_START

RssiMsg.java:
	nescc-mig java $(CFLAGS) $(NESC_PFLAGS) -java-classname=RssiMsg TestAlarm.h rssiMessage_t -o $@

RssiDoneMsg.java:
	nescc-mig java $(CFLAGS) $(NESC_PFLAGS) -java-classname=RssiDoneMsg TestAlarm.h rssiDataDone_t -o $@

Send.class: 
	javac Send.java

Receive.class: RssiMsg.java RssiDoneMsg.java
	javac Receive.java

TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

