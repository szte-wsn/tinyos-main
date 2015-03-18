module AutoTrimP {
	provides interface AutoTrim;
}
implementation {

	#include "InfrastructureSettings.h"
	
	
	#define MAX_PERIOD 100
	#define ACCEPT_PERIOD 70
	#define LOW_PERIOD 40
	
	#define INIT_TRIM1 0
	#define INIT_TRIM2 15
	#define MIN_TRIM 0
	#define MAX_TRIM 15
	
	
	
	
	typedef nx_struct msg_t{
		nx_uint8_t frame;
		nx_uint8_t freq[NUMBER_OF_RX];
		nx_uint8_t phase[NUMBER_OF_RX];
	} msg_t;

	bool isTx = FALSE;
	uint8_t numberOfReceivers = 0;
	
	norace struct {
		uint8_t slotId;
		uint8_t trim;
	} trims[NUMBER_OF_RX];
	
	//tx slots
	struct {
		uint8_t slotId;
		uint8_t receivers[NUMBER_OF_INFRAST_NODES];
		bool receiverOk[NUMBER_OF_INFRAST_NODES];
		uint8_t periods[NUMBER_OF_INFRAST_NODES];
		uint8_t phases[NUMBER_OF_INFRAST_NODES];
		bool tested;
		bool wasLarge;
	} slots[NUMBER_OF_RX];
	
	struct {
		uint8_t moteId;
		struct {
			uint8_t msg_offset;
			uint8_t slotId;
			uint8_t tx1Id;
			uint8_t tx2Id;
			bool accepted;
		} rxs[NUMBER_OF_RX];
	} motes[NUMBER_OF_INFRAST_NODES];
	
	uint8_t getPresetTrim(uint8_t slotId_in){
		return read_uint8_t(&(presetTrims[TOS_NODE_ID-1][slotId_in]));
	}
	
	async command uint8_t AutoTrim.getTrim(uint8_t slotId_in){
		slotId_in = (slotId_in == -1)?0:slotId_in;
		#ifdef USE_PRESET_TRIMS
		return getPresetTrim(slotId_in);
		#else
		int i;
		for(i=0;i<NUMBER_OF_RX;i++){
			if(trims[i].slotId == slotId_in){
				return trims[i].trim;
			}
		}
		return 1;
		#endif
	}
	
	void reducePeriod(uint8_t slotIndex);
	void increasePeriod(uint8_t slotIndex);
	void acceptAll(uint8_t slotIndex);
	void processSchedule();
	
	void calculateTrim(uint8_t slotIndex){
		uint8_t i;
		uint16_t sum = 0;
		float avgPeriod = 0.0;
		uint8_t wasZero = 0;
		for(i=0;i<numberOfReceivers;i++){
			if(!slots[slotIndex].receiverOk[i])
				return;
		}
		for(i=0;i<numberOfReceivers;i++){
			slots[slotIndex].receiverOk[i] = FALSE;
		}
		for(i=0;i<numberOfReceivers;i++){
			if(slots[slotIndex].periods[i] != 0){
				sum+=slots[slotIndex].periods[i];
			}else{
				if(slots[slotIndex].phases[i] == 103 || slots[slotIndex].phases[i] == 104){ //few crossing, large period
					if(slots[slotIndex].tested){
						slots[slotIndex].wasLarge = TRUE;
					}
					reducePeriod(slotIndex);
					return;
				}
				wasZero++;
			}
			
		}
		if(wasZero == numberOfReceivers){
			//reducePeriod(slotIndex);
			return;
		}
		avgPeriod = sum / (numberOfReceivers-wasZero);
		if(avgPeriod <= LOW_PERIOD){
			increasePeriod(slotIndex);
		}
		if(avgPeriod > LOW_PERIOD && avgPeriod<ACCEPT_PERIOD){
			if(slots[slotIndex].tested && slots[slotIndex].wasLarge){
				acceptAll(slotIndex);
				return;
			}else{
				slots[slotIndex].tested = TRUE;
				increasePeriod(slotIndex);
			}
		}
		if(avgPeriod > ACCEPT_PERIOD && avgPeriod < MAX_PERIOD){
			acceptAll(slotIndex);
			return;
		}
		if(avgPeriod > MAX_PERIOD){
			if(slots[slotIndex].tested){
				slots[slotIndex].wasLarge = TRUE;
			}
			reducePeriod(slotIndex);
		}
	}
	
	command void AutoTrim.processSyncMessage(uint8_t senderId, void* payload){
		msg_t* data = (msg_t*)payload;
		uint8_t i=1,j,k,l; //first byte is frameID
		if(!isTx){
			return;
		}
		for(i=1;i<NUMBER_OF_RX+1;i++){ //for all period values
			for(j=0;j<NUMBER_OF_RX;j++){ //for all RX slots
				if( motes[senderId-1].rxs[j].msg_offset == i-1 ){
					if(motes[senderId-1].rxs[j].accepted){
						break;
					}
					if(motes[senderId-1].rxs[j].tx1Id == TOS_NODE_ID || motes[senderId-1].rxs[j].tx2Id == TOS_NODE_ID){
						for(k=0;k<NUMBER_OF_RX;k++){ //for all slots
							if( slots[k].slotId == motes[senderId-1].rxs[j].slotId ){
								for(l=0;l<numberOfReceivers;l++){
									if(slots[k].receivers[l]==senderId){
										if(!slots[k].receiverOk[l]){
											slots[k].periods[l] = data->freq[i-1];
											slots[k].phases[l] = data->phase[i-1];
											slots[k].receiverOk[l] = TRUE;
											return;
										}
									}
								}
								calculateTrim(k);
							}
						}
					}
				}
			}
		}
	}
	
	void reducePeriod(uint8_t slotIndex){
		uint8_t slotId = slots[slotIndex].slotId;
		uint8_t i;
		uint8_t measType = read_uint8_t(&(motesettings[TOS_NODE_ID-1][slotId]));
		if(measType == TX1){
			return;
		}else if(measType == TX2){
			for(i=0;i<NUMBER_OF_RX;i++){
				if(trims[i].slotId == slotId){
					if(trims[i].trim != MAX_TRIM){
						trims[i].trim++;
					}
				}
			}
		}
	}
	
	void increasePeriod(uint8_t slotIndex){
		uint8_t slotId = slots[slotIndex].slotId;
		uint8_t i;
		uint8_t measType = read_uint8_t(&(motesettings[TOS_NODE_ID-1][slotId]));
		if(measType == TX1){
			return;
		}else if(measType == TX2){
			for(i=0;i<NUMBER_OF_RX;i++){
				if(trims[i].slotId == slotId){
					if(trims[i].trim != MIN_TRIM){
						trims[i].trim--;
					}
				}
			}
		}
	}
	void acceptAll(uint8_t slotIndex){
		uint8_t i,j;
		uint8_t slotId = slots[slotIndex].slotId;
		for(i=0;i<numberOfReceivers;i++){
			uint8_t receiverId = slots[slotIndex].receivers[i];
			for(j=0;j<NUMBER_OF_RX;j++){
				if(motes[receiverId-1].rxs[j].slotId == slotId){
					motes[receiverId-1].rxs[j].accepted = TRUE;
				}
			}
		}
	}
	
	
	command void AutoTrim.processSchedule(){
		//init
		uint8_t i,j,k,l,cnt=0,cnt2=0;
		
		// TX mote?
		for(i=0;i<NUMBER_OF_SLOTS;i++){
			uint8_t measType = read_uint8_t(&(motesettings[TOS_NODE_ID-1][i]));
			if(measType == TX1 || measType==TX2){
				isTx = TRUE;
			}
		}
		if(!isTx){
			return;
		}
		//how many receivers
		for(i=0;i<NUMBER_OF_SLOTS;i++){
			uint8_t measType = read_uint8_t(&(motesettings[TOS_NODE_ID-1][i]));
			if(measType == TX1 || measType==TX2){
				for(j=0;j<NUMBER_OF_INFRAST_NODES;j++){
					uint8_t temp = read_uint8_t(&(motesettings[j][i]));
					if(temp == RX){
						numberOfReceivers++;
					}
				}
				break;
			}
		}
		//init trim values
		cnt = 0;
		for(i=0;i<NUMBER_OF_SLOTS;i++){
			uint8_t measType = read_uint8_t(&(motesettings[TOS_NODE_ID-1][i]));
			if(measType == TX1){
				trims[cnt].slotId = i;
				trims[cnt++].trim = INIT_TRIM1;
			}
			if(measType == TX2){
				trims[cnt].slotId = i;
				trims[cnt++].trim = INIT_TRIM2;
			}
		}
		//init tx slots
		cnt = 0;
		for(i=0;i<NUMBER_OF_SLOTS;i++){
			uint8_t measType = read_uint8_t(&(motesettings[TOS_NODE_ID-1][i]));
			if(measType == TX1 || measType==TX2){
				slots[cnt].slotId = i;
				slots[cnt].tested = FALSE;
				slots[cnt].wasLarge = FALSE;
				cnt2 = 0;
				for(j=0;j<NUMBER_OF_INFRAST_NODES;j++){
					uint8_t temp = read_uint8_t(&(motesettings[j][i]));
					if(temp == RX){
						slots[cnt].receivers[cnt2] = j+1;
						slots[cnt].receiverOk[cnt2++] = FALSE;
					}
				}
				cnt++;
			}
		}
		//init motes
		for(i=0;i<NUMBER_OF_INFRAST_NODES;i++){
			motes[i].moteId = i+1;
			cnt = 0;
			cnt2 = 0;
			for(j=0;j<NUMBER_OF_SLOTS;j++){
				uint8_t temp = read_uint8_t(&(motesettings[i][j]));
				if(temp == RX){
					motes[i].rxs[cnt].slotId = j;
					motes[i].rxs[cnt].msg_offset = cnt2++;
					motes[i].rxs[cnt].accepted = FALSE;
					for(l=0;l<NUMBER_OF_INFRAST_NODES;l++){
						uint8_t temp3 = read_uint8_t(&(motesettings[l][j]));
						if(temp3==TX1){
							motes[i].rxs[cnt].tx1Id = l+1;
						}
						if(temp3==TX2){
							motes[i].rxs[cnt].tx2Id = l+1;
						}
					}
					cnt++;
				}
				/*if(temp == SSYN){ //j= sync frame number
					for(k=0;k<NUMBER_OF_SLOTS;k++){
						uint8_t slotIndex = (k+j)%NUMBER_OF_SLOTS;
						uint8_t temp2 = read_uint8_t(&(motesettings[i][slotIndex]));
						if(temp2 == RX){
							motes[i].rxs[cnt].slotId = slotIndex;
							motes[i].rxs[cnt].msg_offset = cnt2++;
							motes[i].rxs[cnt].accepted = FALSE;
							for(l=0;l<NUMBER_OF_INFRAST_NODES;l++){
								uint8_t temp3 = read_uint8_t(&(motesettings[l][slotIndex]));
								if(temp3==TX1){
									motes[i].rxs[cnt].tx1Id = l+1;
								}
								if(temp3==TX2){
									motes[i].rxs[cnt].tx2Id = l+1;
								}
							}
							cnt++;
						}
					}
				}*/
			}
		}
	}

}
