COMPONENT=TestAlarmC
BUILD_EXTRA_DEPS += Send.class Receive.class
CLEAN_EXTRA = *.class RssiMsg.java CommandMsg.java RssiDoneMsg.java
BOOTLOADER=tosboot
CFLAGS += -DTOSH_DATA_LENGTH=114
CFLAGS += -DUCMINI_REV=101
CFLAGS += -DCONTINOUS_WAVE
# CFLAGS += -DDIAGMSG_RADIO
# CFLAGS += -DRADIO_DEBUG
# CFLAGS += -DDIAGMSG_SERIAL_START
#for the mini 2
CFLAGS+=-DDISABLE_BATTERY_CHECK
CFLAGS += -I$(TOSDIR)/lib/diagmsg

RssiMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=RssiMsg TestAlarm.h rssiMessage_t -o $@

RssiDoneMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=RssiDoneMsg TestAlarm.h rssiDataDone_t -o $@

Send.class: 
	javac Send.java

Receive.class: RssiMsg.java RssiDoneMsg.java
	javac Receive.java

include $(MAKERULES)
