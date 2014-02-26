COMPONENT=NullAppC
BOOTLOADER=tosboot
# CFLAGS+= -DUCMINI_REV=101
# CFLAGS+=-DDIAGMSG_RECORDED_MSGS=100
BUILD_EXTRA_DEPS += Send.class Receive.class
CLEAN_EXTRA = *.class RssiMsg.java CommandMsg.java RssiDoneMsg.java RssiMsg.py *.pyc

RssiMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=RssiMsg interferencemsg.h rssiMessage_t -o $@

RssiDoneMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=RssiDoneMsg interferencemsg.h rssiDataDone_t -o $@
	
RssiMsg.py:
	mig python -target=null $(CFLAGS) -python-classname=RssiMsg interferencemsg.h rssiMessage_t -o $@

CommandMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=CommandMsg interferencemsg.h commandMessage_t -o $@

Send.class: CommandMsg.java
	javac Send.java

Receive.class: RssiMsg.java RssiDoneMsg.java
	javac Receive.java

Receive.py: RssiMsg.py

include $(MAKERULES)

