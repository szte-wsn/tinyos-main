COMPONENT=ApplicationC
BUILD_EXTRA_DEPS += java
CLEAN_EXTRA = *.class ctrlMsg.java ctrltsMsg.java dataMsg.java internalCommandConsts.java externalCommandConsts.java
CFLAGS += -Iadc/
CFLAGS += -Ibpm/
CFLAGS += -I$(TOSDIR)/lib/StreamStorage2
CFLAGS += -I$(TOSDIR)/lib/StreamUploaderSH
CFLAGS += -I$(TOSDIR)/lib/FastSerial
CFLAGS += -I..
CFLAGS += -DDISABLE_SERIAL_RESET
#CFLAGS += -Iss
#CFLAGS += -Isf
SENSORBOARD=ucsbacoustic
CFLAGS += -DRF230_DEF_CHANNEL=15
CFLAGS += -DRFA1_DEF_CHANNEL=15
CFLAGS += -DSAMP_T=15
CFLAGS += -DSAVE_WAVE=1
CFLAGS += -DWAIT_AFTER_START=10
CFLAGS += -DSOFTWAREACK_TIMEOUT=1000
CFLAGS += -DTOSH_DATA_LENGTH=28

# CFLAGS += -DDIAGMSG_RECORDED_MSGS=100
# CFLAGS += -DDIAGMSG_SERIAL_START

ctrlMsg.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=org.szte.wsn.downloader.ctrlMsg $(TOSDIR)/lib/StreamUploaderSH/StreamUploader.h ctrl_msg_t -o $@

ctrltsMsg.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=org.szte.wsn.downloader.ctrltsMsg $(TOSDIR)/lib/StreamUploaderSH/StreamUploader.h ctrlts_msg_t -o $@

dataMsg.java:
	mig java -target=$(PLATFORM) $(CFLAGS) -java-classname=org.szte.wsn.downloader.dataMsg $(TOSDIR)/lib/StreamUploaderSH/StreamUploader.h data_msg_t -o $@

internalCommandConsts.java:
	ncg java -target=$(PLATFORM) $(CFLAGS)  -java-classname=org.szte.wsn.downloader.internalCommandConsts $(TOSDIR)/lib/StreamUploaderSH/StreamUploader.h CMD_ERASE -o $@

externalCommandConsts.java:
	ncg java -target=$(PLATFORM) $(CFLAGS)  -java-classname=org.szte.wsn.downloader.externalCommandConsts ../EchoRanger.h CMD_MEASNOW CMD_SETGAIN_DUAL CMD_SETGAIN CMD_SETWAIT -o $@

java: ctrlMsg.java ctrltsMsg.java dataMsg.java internalCommandConsts.java externalCommandConsts.java

include $(MAKERULES)
