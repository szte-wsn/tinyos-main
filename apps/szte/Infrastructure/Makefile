COMPONENT=TestAlarmC
# BOOTLOADER=tosboot
# include ../Makecommon

CFLAGS += -DCONTINOUS_WAVE
CFLAGS += -I$(TOSDIR)/lib/diagmsg
#for the mini 2
CFLAGS+=-DDISABLE_BATTERY_CHECK
#for the mini 1
CFLAGS += -DUCMINI_REV=101
CFLAGS += -DUCPROTONA_REV=20
CFLAGS += -DNO_COLLISION_LAYER
#should be at least: 6+NUMBER_OF_RX*5
CFLAGS += -DTOSH_DATA_LENGTH=100

CFLAGS += -DSEND_WAVEFORM
CFLAGS += -DWFSEND_STARTINDEX=0

# CFLAGS += -DDISABLE_PROCESSING
# CFLAGS += -DCW_SYNC_TEST
# CFLAGS += -DDEBUG_COLLECTOR

# CFLAGS += -DDIAGMSG_SERIAL_START
# CFLAGS += -DDIAGMSG_RECORDED_MSGS=70
# CFLAGS += -DDEBUG_MEASUREWAVE
# CFLAGS += -DDEBUG_FILTER


TOSMAKE_PRE_EXE_DEPS = DataCollector.class ProcessWave.class DrawWaveform.class WaveForm.py SyncMsg.py java/WaveForm.java java/Consts.java
TOSMAKE_CLEAN_EXTRA = *.class *.pyc $(TOSMAKE_PRE_EXE_DEPS) __pycache__ java/WaveForm.java java/Consts.java

DataCollector.class: DataCollector.java
	javac $?

ProcessWave.class: ProcessWave.java
	javac $?

DrawWaveform.class: DrawWaveform.java
	javac $?

WaveForm.py:
	nescc-mig python $(CFLAGS) $(NESC_PFLAGS) TestAlarm.h -python-classname=WaveForm wave_message_t -o $@

java/WaveForm.java:
	nescc-mig java $(CFLAGS) $(NESC_PFLAGS) TestAlarm.h -java-classname=WaveForm wave_message_t -o $@

java/Consts.java:
	nescc-ncg java $(CFLAGS) $(NESC_PFLAGS) TestAlarm.h -java-classname=Consts BUFFER_LEN_MIG -o $@

SyncMsg.py: 
	nescc-mig python $(CFLAGS) $(NESC_PFLAGS) TestAlarm.h -python-classname=SyncMsg real_sync_message_t -o $@


TINYOS_ROOT_DIR?=../../..
include $(TINYOS_ROOT_DIR)/Makefile.include
