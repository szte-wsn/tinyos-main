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
CFLAGS += -DRFA1_RADIO_TIMER1_MCU
#should be at least: 6+NUMBER_OF_RX*5
CFLAGS += -DTOSH_DATA_LENGTH=100

#Enables auto Trim algorithm
# CFLAGS += -DENABLE_AUTOTRIM
#Measure types: FOUR_MOTE, FOUR_MOTE_WF, PHASEMAP_TEST_13, PHASEMAP_TEST_18, PROCESSING_DEBUG
CFLAGS += -DMEASURE_TYPE=PHASEMAP_TEST_8

#disables waveform processing
# CFLAGS += -DDISABLE_PROCESSING
#copies the buffer before processing (useful for waveform downloading)
# CFLAGS += -DMEASUREWAVE_SAVE_BUFFER
#enables GPIO based sync testing (with logic analyzer)
# CFLAGS += -DCW_SYNC_TEST
#sets the period and all bytes of the waveform to the current slot's number. Useful for debugging data downloading
# CFLAGS += -DDEBUG_COLLECTOR
#measures cpu load with infinite task. Overwrites measured frequency
# CFLAGS += -DMEASURE_CPU_LOAD

#diagmsg based debugs
#diagmsg configs
# CFLAGS += -DDIAGMSG_SERIAL_START
# CFLAGS += -DDIAGMSG_RECORDED_MSGS=70
#counts dropped frames
# CFLAGS += -DTEST_CALCULATION_TIMING
#measures processing time (might give false readings due to interrupts)
# CFLAGS += -DMEASUREWAVE_PROFILER
#radio debug stuff
# CFLAGS += -DRADIO_DEBUG
# CFLAGS += -DTRAFFIC_MONITOR

#slightly increases the code size
CFLAGS += -DENABLE_DEBUG_SLOTS

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
