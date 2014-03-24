COMPONENT=BaseStationC
CFLAGS += -DCC2420_NO_ACKNOWLEDGEMENTS
CFLAGS += -DCC2420_NO_ADDRESS_RECOGNITION
CFLAGS += -DTASKLET_IS_TASK
CFLAGS += -DTOSH_DATA_LENGTH=110
CFLAGS += -DUCMINI_REV=101
BUILD_EXTRA_DEPS = BaseStationApp.class
CLEAN_EXTRA = *.class CommandMsg.java MeasureMsg.java GetSliceMsg.java AnnouncementMsg.java FreeMsg.java

CommandMsg.java: BaseStation.h
	mig java -target=null -java-classname=CommandMsg BaseStation.h CommandMsg -o $@

CommandMsg.class: CommandMsg.java
	javac CommandMsg.java

MeasureMsg.java: BaseStation.h
	mig java -target=null -java-classname=MeasureMsg BaseStation.h MeasureMsg -o $@

MeasureMsg.class: MeasureMsg.java
	javac MeasureMsg.java

GetSliceMsg.java: BaseStation.h
	mig java -target=null -java-classname=GetSliceMsg BaseStation.h GetSliceMsg -o $@

GetSliceMsg.class: GetSliceMsg.java
	javac GetSliceMsg.java

AnnouncementMsg.java: BaseStation.h
	mig java -target=null -java-classname=AnnouncementMsg BaseStation.h AnnouncementMsg -o $@

AnnouncementMsg.class: AnnouncementMsg.java
	javac AnnouncementMsg.java

FreeMsg.java: BaseStation.h
	mig java -target=null -java-classname=FreeMsg BaseStation.h FreeMsg -o $@

FreeMsg.class: FreeMsg.java
	javac FreeMsg.java



BaseStationApp.class: BaseStationApp.java GetSliceMsg.class AnnouncementMsg.class MeasureMsg.class CommandMsg.class FreeMsg.class
	javac BaseStationApp.java

include $(MAKERULES)
