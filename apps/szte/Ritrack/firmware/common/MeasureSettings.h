#ifndef __MEASURESETTINGS_H__
#define __MEASURESETTINGS_H__

#include "RadioConfig.h" //just for DEF_RFPOWER

#ifndef ENABLE_AUTOTRIM
enum slotTiming {
	MEAS_SLOT = 2560,
	SYNC_SLOT = 4800,
	DEBUG_SLOT = 96000UL*NUMBER_OF_RX,
	WAIT_SLOT_1 = 2000,
	WAIT_SLOT_10 = 20000UL,
	WAIT_SLOT_100 = 200000UL,
	WAIT_SLOT_CAL = 2976,
};
#else
//increased slot times because of processing overhead    ***NOT OPTIMIZED YET***
enum slotTiming {
	MEAS_SLOT = 3200, 
	SYNC_SLOT = 16000,
	DEBUG_SLOT = 96000UL*NUMBER_OF_RX,
	WAIT_SLOT_1 = 2000,
	WAIT_SLOT_10 = 20000UL,
	WAIT_SLOT_100 = 200000UL,
	WAIT_SLOT_CAL = 2976,
};
#endif

//rx-tx diff: 130us
enum inSlotTiming {
	SENDING_TIME = 1920UL,
	TX1_THRESHOLD = 0UL,
	TX2_THRESHOLD = 200UL,
	RX_THRESHOLD = 200UL,
};

enum measureParameters {
	CHANNELA = 17,
	TRIM1A = 2,
	TRIM2A = 4,
	CHANNELB = 17,
	TRIM1B = 2,
	TRIM2B = 4,
	POWERA = RFA1_DEF_RFPOWER,
	POWERB = RFA1_DEF_RFPOWER,
};

#endif