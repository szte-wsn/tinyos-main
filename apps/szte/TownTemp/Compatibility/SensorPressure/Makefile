COMPONENT=TempWriteAppC
BUILD_EXTRA_DEPS = SerialReceive.class
CLEAN_EXTRA = *.class SerialMsg.java ControlMsg.java SerialConsts.java
CFLAGS += -DCC2420_DEF_CHANNEL=16
CFLAGS += -DRFA1_DEF_CHANNEL=16
CFLAGS += -DRF230_DEF_CHANNEL=16
CFLAGS += -DLOW_POWER_LISTENING
CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=0
CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=30720
CFLAGS += -DDELAY_AFTER_RECEIVE=200
CFLAGS += -DSTM25P_HW_POWER_DISABLE
CFLAGS += -DUCMINI_REV=101

SerialMsg.java: TempStorage.h
	nescc-mig java $(CFLAGS) $(NESC_PFLAGS) -java-classname=SerialMsg java TempStorage.h BlinkToRadioMsg -o $@

ControlMsg.java: TempStorage.h
	nescc-mig java $(CFLAGS) $(NESC_PFLAGS) -java-classname=ControlMsg java TempStorage.h ControlMsg -o $@

SerialConsts.java: TempStorage.h
	nescc-ncg java $(CFLAGS) $(NESC_PFLAGS) -java-classname=SerialConsts java TempStorage.h END_VALUE -o $@

SerialReceive.class: SerialMsg.java ControlMsg.java SerialConsts.java
	javac SerialReceive.java

TINYOS_ROOT_DIR?=../../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

