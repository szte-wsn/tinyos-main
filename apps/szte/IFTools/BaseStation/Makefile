COMPONENT=BaseStationC
CFLAGS += -DCC2420_NO_ACKNOWLEDGEMENTS
CFLAGS += -DCC2420_NO_ADDRESS_RECOGNITION
CFLAGS += -DTASKLET_IS_TASK
include ../../Makecommon

include $(MAKERULES)
# ifeq ($(PLATFORM),$(filter $(PLATFORM),ucmini ucprotona ucprotonb ucbase ucbasedrd))
#   CFLAGS += -DPLATFORM_BAUDRATE=500000U
# else
#   CFLAGS += -DPLATFORM_BAUDRATE=230400U
# endif
