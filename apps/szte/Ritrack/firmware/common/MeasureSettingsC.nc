#include "InfrastructureSettings.h"
#include "MeasureSettings.h"
module MeasureSettingsC {
	provides interface MeasureSettings;
}
implementation {
	
// 	inline uint8_t getSlotType(uint8_t slotNumber){
// 		return  read_uint8_t(&(motesettings[TOS_NODE_ID-1][slotNumber]));
// 	}

	async command uint8_t MeasureSettings.getChannel(uint8_t slotType, uint8_t slotNumber){
		switch( slotType ){
			case TX1B:
			case TX2B:
			case RXB:
				return CHANNELB;
			default:
				return CHANNELA;
		}
	}
	
	async command uint8_t MeasureSettings.getTxPower(uint8_t slotType, uint8_t slotNumber){
		switch( slotType ){
			case TX1B:
			case TX2B:
				return POWERB;
			default:
				return POWERA;
		}
	}

#if !defined(USE_PRESET_TRIMS) && !defined(TRIM_MOTE)
#define TRIM_MOTE 0
#warning "TRIM_MOTE not defined, using 0"
#endif
	async command uint8_t MeasureSettings.getTrim(uint8_t slotType, uint8_t slotNumber){
		#ifdef USE_PRESET_TRIMS
		return read_uint8_t(&(presetTrims[TOS_NODE_ID-1][slotNumber]));
		#else
		switch( slotType ){
			case TX1B:
				return TRIM1B + TRIM_MOTE;
			case TX2B:
				return TRIM2B + TRIM_MOTE;
			case TX2A:
				return TRIM2A + TRIM_MOTE;
			default:
				return TRIM1A + TRIM_MOTE;
		}
		#endif
	}
	
	async command uint16_t MeasureSettings.getSendTime(){
		return SENDING_TIME;
	}
	
	async command uint32_t MeasureSettings.getSlotTime(uint8_t slotType){
		switch( slotType ){
			case RSYN:
			case SSYN:
			case DSYN:
				return SYNC_SLOT;
			case TX1A:
			case TX2A:
			case TX1B:
			case TX2B:
			case RXA:
			case RXB:
			case NTRX:
				return MEAS_SLOT;
			case W1:
				return WAIT_SLOT_1;
			case W10:
				return WAIT_SLOT_10;
			case W100:
				return WAIT_SLOT_100;
			case DEB:
			case NDEB:
				return DEBUG_SLOT;
			default: //should never happen
				return 0;
		}
	}
	
	async command uint16_t MeasureSettings.getDelay(uint8_t slotType){
		switch(slotType){
			case TX1A:
			case TX1B:
				return TX1_THRESHOLD;
			case TX2A:
			case TX2B:
				return TX2_THRESHOLD;
			case RXA:
			case RXB:
				return RX_THRESHOLD;
			default:
				return 0;
		}
	}
}