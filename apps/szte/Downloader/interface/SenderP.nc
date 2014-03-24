#include "Sender.h"
#include "math.h"

module SenderP{
  provides interface Storage;
  uses{
  	interface Leds;
    interface AMSend as radSenMeasureMsg;
	interface AMSend as radSenAnnouncementMsg;
  }
}

implementation {	
	norace data_t buffer[MAX_MEASUREMENT_NUMBER];		
	uint8_t deleteMes[DELETE_MES_NUMBER];		//adat torlesnel hasznalom
	uint8_t mes_id = 1; 	//csomagazonosito
	uint8_t packet_id = 0;		//megorzi, hogy hanyadik csomagot kezdte el kikuldeni

	norace uint8_t data_number = 0; //mennyi adat van a bufferben

	uint8_t seq_num = 0;		//hanyadik szeletet kuldjuk el a meresbol. A 0.dik szelet az elso resz a meresbol		
	
	message_t pkt;

	uint8_t mes_id_sS, slice_sS, index_sS;	//sliceSend task parameterei

	bool sending = FALSE;		//ha mar elkezdtunk a bazissal kommunikalni akkor true
	bool slice_send = FALSE;	//ha csak szeletet kuldunk (a szeletkereskor TRUE-t vesz fel)


	task void AnnouncementSend() {
		AnnouncementMsg* btrpkt = (AnnouncementMsg*) (call radSenAnnouncementMsg.getPayload(&pkt, sizeof(AnnouncementMsg)));
		btrpkt -> mes_number = data_number;		//mennyi merest taroltunk el osszesen

		if(call radSenAnnouncementMsg.send(1, &pkt, sizeof(AnnouncementMsg))==SUCCESS) { // 1 - base station
		}
	}	

	async command error_t Storage.store(uint8_t data[]) {
		atomic {
			int i;
			int j;
			if(data_number >= MAX_MEASUREMENT_NUMBER) {			//belefer-e az adat
				return FAIL;
			}
			for(i = 0; i < MAX_MEASUREMENT_NUMBER; i++) {
				if(buffer[i].mes_id == 0) {			//ures az adott buffer
					for(j = 0; j < MEASUREMENT_LENGTH; j++)
						buffer[i].data[j] = data[j];	
					buffer[i].mes_id = mes_id;
					if(FALSE == sending) {		//meg nem kezdtunk el a bazisnak uzenetet kuldeni
						call Leds.set(4);
						buffer[data_number].valid = TRUE;
					} else {
						call Leds.set(1);
						buffer[data_number].valid = FALSE;			//kuldes kozben tortent az adat letarolas
					}
					mes_id++;		//meresazonosito		
					data_number++;	//mennyi meres van a bufferben
					break;
				}			
			}
		}
		post AnnouncementSend();		//kikuldjuk, hogy mennyi adatunk van
		return SUCCESS;
	}


	task void send() {
		int i;
		int j;
		uint8_t width = 0;
		MeasureMsg* btrpkt = (MeasureMsg*) (call radSenMeasureMsg.getPayload(&pkt, sizeof(MeasureMsg)));

		for(i=0; i<MAX_MEASUREMENT_NUMBER; i++)	{	//megnezzuk, hogy melyik csomag valid, mehet kikuldesre
				if(packet_id != 0 || (buffer[i].mes_id != 0 && TRUE == buffer[i].valid)) {
					if(packet_id == 0)					
						packet_id = i;				
					btrpkt -> mes_id = buffer[packet_id].mes_id;
					btrpkt -> seq_num = seq_num;
	//adatfeltoltes
					for(j=0; j<(DATA_LENGTH); j++) {	
						if( (j+(seq_num*(DATA_LENGTH))) >= MEASUREMENT_LENGTH)  	//vegere ertunk az adott meresnek
							btrpkt -> data[j] = 0;								//a maradek payload-ot nullaval toltsuk fel
						else {
							btrpkt -> data[j] = buffer[packet_id].data[j+(seq_num*(DATA_LENGTH))];	
							width++;		//meddig tart a valos meres hossza
						}
					}
					break;
				}
		}
		btrpkt -> slice_width = width;	

		if(call radSenMeasureMsg.send(1, &pkt, sizeof(MeasureMsg))==SUCCESS) { 	// 1 - base station
			seq_num = seq_num + 1;			//sikeres kikuldes eseten 1-el novekszik a szelet szama
		}
	}

	command error_t Storage.take() 	{
		if(data_number <= 0) {
			return FAIL;	//nincs bufferben adat
		}
		atomic { sending = TRUE; }	//elkezdunk kuldeni
		post send();
		return SUCCESS;		
	}


	event void radSenMeasureMsg.sendDone(message_t *msg, error_t error) {	
	if(slice_send == FALSE) {		//ha nem szeletet kuldtunk
		if(&pkt == msg && seq_num<ceil((double)MEASUREMENT_LENGTH/(DATA_LENGTH))) {	//addig kuldjuk a meres szeleteit, amig vegeig nem erunk			
			post send();
		} else {			//elkuldte az osszes szeletet a meresbol
			seq_num = 0;		//vegehez ertunk az adott meresnek, igy nullazuk a szelet szamot
			packet_id = 0;
		}
	} else
		slice_send = FALSE;
	}

	task void delete() {
		int i;
//		int j;
		int k;
		for(k = 0; k < DELETE_MES_NUMBER; k++) {
			for(i = 0; i < MAX_MEASUREMENT_NUMBER; i++) {
				if(buffer[i].mes_id != 0 && deleteMes[k] != 0 && deleteMes[k] == buffer[i].mes_id) {	
					buffer[i].mes_id = 0;
					data_number--;
					break;
				}	
			}
		}
		post AnnouncementSend();	
		signal Storage.deleteDone();
	}

	command error_t Storage.delete(uint8_t* del) {
		int i;
		for(i=0; i<DELETE_MES_NUMBER; i++) {
			deleteMes[i] = del[i];
		}
		post delete();
		return SUCCESS;
	}

	task void sliceSend() {
		int i;
		uint8_t width = 0;
		MeasureMsg* btrpkt = (MeasureMsg*) (call radSenMeasureMsg.getPayload(&pkt, sizeof(MeasureMsg)));
		btrpkt -> mes_id = mes_id_sS;
		btrpkt -> seq_num = slice_sS;

//adatfeltoltes
		for(i=0; i<(DATA_LENGTH); i++) {
			if( (i+slice_sS*(DATA_LENGTH)) >= MEASUREMENT_LENGTH)  	//vegere ertunk az adott meresnek
				btrpkt -> data[i] = 0;								//a maradek payload-ot nullaval toltsuk fel
			else {
				btrpkt -> data[i] = buffer[index_sS].data[i+slice_sS*(DATA_LENGTH)];	//DATA_LENTGT=PAYLOAD_LENGTH-3
					width++;
			}
		}
		btrpkt -> slice_width = width;	
		if(call radSenMeasureMsg.send(1, &pkt, sizeof(MeasureMsg))==SUCCESS) { // 1 - base station
		}
	}

	command error_t Storage.getSlice(uint8_t mes_id_p, uint8_t slice_p) {
		int i = 0;
		if(data_number <= 0) {
			return FAIL;	//nincs bufferben adat
		}
		for(i=0; i<MAX_MEASUREMENT_NUMBER; i++) {		//kikeresi, hogy az adott csomagszam, hanyadik index a bufferben
			if(mes_id_p == buffer[i].mes_id) {
				index_sS = i;
				break;
			}
		}
		mes_id_sS = mes_id_p;
		slice_sS = slice_p;
		slice_send = TRUE;
		post sliceSend();
		return SUCCESS;	
	}

	command error_t Storage.commEnd() {		//vege a kommunikacionak a base stationel
		atomic { 
			int i;
			sending = FALSE; 
			for(i = 0; i < MAX_MEASUREMENT_NUMBER; i++) {
				if(buffer[i].mes_id != 0) 				//nem ures a buffer 
					buffer[data_number].valid = TRUE;
			}
			packet_id = 0;
			seq_num = 0;
		}
		return SUCCESS;
	}

	event void radSenAnnouncementMsg.sendDone(message_t *msg, error_t error) {
	}

	
	default event void Storage.deleteDone() {
	}
	
	default event void Storage.takeDone() {
	}

}
