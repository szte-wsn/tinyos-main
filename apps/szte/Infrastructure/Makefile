COMPONENT=TestAlarmC
BUILD_EXTRA_DEPS += Send.class Receive.class
CLEAN_EXTRA = *.class RssiMsg.java CommandMsg.java RssiDoneMsg.java
BOOTLOADER=tosboot
include ../Makecommon

CFLAGS += -DCONTINOUS_WAVE
CFLAGS += -I$(TOSDIR)/lib/diagmsg
#for the mini 2
CFLAGS+=-DDISABLE_BATTERY_CHECK
#for the mini 1
CFLAGS += -DUCMINI_REV=101

# CFLAGS += -DDIAGMSG_RADIO
# CFLAGS += -DRADIO_DEBUG
CFLAGS += -DDIAGMSG_SERIAL_START

RssiMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=RssiMsg TestAlarm.h rssiMessage_t -o $@

RssiDoneMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=RssiDoneMsg TestAlarm.h rssiDataDone_t -o $@

Send.class: 
	javac Send.java

Receive.class: RssiMsg.java RssiDoneMsg.java
	javac Receive.java

include $(MAKERULES)
