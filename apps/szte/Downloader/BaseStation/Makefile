COMPONENT=BaseStationC
CFLAGS += -DTOS_DATA_LENGTH=110
CFLAGS += -DUCMINI_REV=101
BUILD_EXTRA_DEPS = BaseStationApp.class
CLEAN_EXTRA = *.class CommandMsg.java RadioDataMsg.java GetSliceMsg.java MesNumberMsg.java LoginMoteMsg.java

CommandMsg.java: BaseStation.h
	mig java -target=null -java-classname=CommandMsg BaseStation.h CommandMsg -o $@

CommandMsg.class: CommandMsg.java
	javac CommandMsg.java

RadioDataMsg.java: BaseStation.h
	mig java -target=null -java-classname=RadioDataMsg BaseStation.h RadioDataMsg -o $@

RadioDataMsg.class: RadioDataMsg.java
	javac RadioDataMsg.java

GetSliceMsg.java: BaseStation.h
	mig java -target=null -java-classname=GetSliceMsg BaseStation.h GetSliceMsg -o $@

GetSliceMsg.class: GetSliceMsg.java
	javac GetSliceMsg.java

MesNumberMsg.java: BaseStation.h
	mig java -target=null -java-classname=MesNumberMsg BaseStation.h MesNumberMsg -o $@

MesNumberMsg.class: MesNumberMsg.java
	javac MesNumberMsg.java

LoginMoteMsg.java: BaseStation.h
	mig java -target=null -java-classname=LoginMoteMsg BaseStation.h LoginMoteMsg -o $@

LoginMoteMsg.class: LoginMoteMsg.java
	javac LoginMoteMsg.java



BaseStationApp.class: BaseStationApp.java GetSliceMsg.class MesNumberMsg.class RadioDataMsg.class CommandMsg.class LoginMoteMsg.class
	javac BaseStationApp.java

include $(MAKERULES)
