COMPONENT=NullAppC
# CFLAGS+= -DUCMINI_REV=101
BUILD_EXTRA_DEPS += Receive.class
CLEAN_EXTRA = *.class RssiMsg.java

RssiMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=RssiMsg rssimessage.h rssiMessage -o $@

Receive.class: RssiMsg.java

include $(MAKERULES)

