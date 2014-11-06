COMPONENT=NullAppC
CFLAGS+= -I..
CFLAGS+=-DDIAGMSG_SERIAL_START
CFLAGS+=-DDIAGMSG_RECORDED_MSGS=150

#for the mini 2
CFLAGS+=-DDISABLE_BATTERY_CHECK
#for the mini 1
CFLAGS += -DUCMINI_REV=101
#for protona
CFLAGS += -DUCPROTONA_REV=20

TestSerial.class: $(wildcard *.java) TestSerialMsg.java
	javac -target 1.4 -source 1.4 *.java

TestSerialMsg.java:
	nescc-mig java $(CFLAGS) -java-classname=TestSerialMsg TestSerial.h test_serial_msg -o $@


TINYOS_ROOT_DIR?=../../../..
include $(TINYOS_ROOT_DIR)/Makefile.include

