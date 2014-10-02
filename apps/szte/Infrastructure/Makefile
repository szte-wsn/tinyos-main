COMPONENT=TestAlarmC
# BOOTLOADER=tosboot
# include ../Makecommon

CFLAGS += -DCONTINOUS_WAVE
CFLAGS += -DCW_SYNC_TEST
CFLAGS += -I$(TOSDIR)/lib/diagmsg
#for the mini 2
CFLAGS+=-DDISABLE_BATTERY_CHECK
#for the mini 1
CFLAGS += -DUCMINI_REV=101
CFLAGS += -DUCPROTONA_REV=20
CFLAGS += -DNO_COLLISION_LAYER
#should be at least: 6+NUMBER_OF_RX*5
CFLAGS += -DTOSH_DATA_LENGTH=100

# CFLAGS += -DDIAGMSG_SERIAL_START
# CFLAGS += -DDIAGMSG_RECORDED_MSGS=80
# CFLAGS += -DSEND_WAVEFORM
# CFLAGS += -DDEBUG_MEASUREWAVE
# CFLAGS += -DDEBUG_FILTER

TOSMAKE_PRE_EXE_DEPS = DataCollector.class ProcessWave.class DrawWaveform.class
TOSMAKE_CLEAN_EXTRA = *.class

DataCollector.class: DataCollector.java
	javac DataCollector.java

ProcessWave.class: ProcessWave.java
	javac ProcessWave.java

DrawWaveform.class: DrawWaveform.java
	javac DrawWaveform.java


TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
