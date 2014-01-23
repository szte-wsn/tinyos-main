COMPONENT=NullAppC
CFLAGS+= -DUCMINI_REV=101
BUILD_EXTRA_DEPS += Receive.class Send.class
CLEAN_EXTRA = *.class RssiMsg.java CommandMsg.java

RssiMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=RssiMsg interferencemsg.h rssiMessage_t -o $@

CommandMsg.java:
	mig java -target=null $(CFLAGS) -java-classname=CommandMsg interferencemsg.h commandMessage_t -o $@

Receive.class: RssiMsg.java

Send.class: CommandMsg.java
	javac Send.java

include $(MAKERULES)

