#include "Sender.h"
#include "math.h"

module SenderP{
  provides interface Storage;
  uses{
    interface AMSend as radSenSenderMsg;
	interface AMSend as radSenMesNumberMsg;
  }
}

implementation {	
	data_t buffer[MAX_MEASUREMENT_NUMBER];		
	uint8_t getData;		//a kivett meres
	uint8_t mes_id = 0; 	//tarolja, hogy hanyadik merest taroljuk el. Minden store meghivasnal novekszik 1-el. Deletenel pedig 0-re allitodik

	uint8_t temp_mes_id = 0;	//segit a sendnel megallapitani, hogy hanyadik merest kuldjuk ki
	uint8_t seq_num = 0;		//hanyadik szeletet kuldjuk el a meresbol. A 0.dik szelet az elso resz a meresbol		
	
	message_t pkt;

	uint8_t mes_id_sS, slice_sS;	//sliceSend task parameterei

	bool sending = FALSE;		//ha mar elkezdtunk a bazissal kommunikalni akkor true
	data_t tmp_buffer[MAX_MEASUREMENT_NUMBER];	//ha sending=true, akkor ezt hasznaljuk ideiglenesen
	uint8_t tmp_mes_id = 0;		//ha sending=true, akkor hasznaljuk
	bool slice_send = FALSE;	//ha csak szeletet kuldunk (a szeletkereskor TRUE-t vesz fel)

	
	async command error_t Storage.store(uint8_t data[]) {
		atomic {
			int i = 0;
			if(sending == FALSE) {	
				if(mes_id >= MAX_MEASUREMENT_NUMBER) {			//belefer-e az adat
					return FAIL;
				}
				for(i = 0; i < MEASUREMENT_LENGTH; i++)
					buffer[mes_id].data[i] = data[i];	
				buffer[mes_id].mes_id = mes_id;
				mes_id = mes_id + 1;
			} else {
				if(tmp_mes_id >= MAX_MEASUREMENT_NUMBER) {			//belefer-e az adat
					return FAIL;
				}
				for(i = 0; i < MEASUREMENT_LENGTH; i++)
					tmp_buffer[tmp_mes_id].data[i] = data[i];	//data also 8 bitje mask
				tmp_buffer[tmp_mes_id].mes_id = tmp_mes_id;
				tmp_mes_id = tmp_mes_id + 1;
			}
			return SUCCESS;
		}
	}


	task void send() {
		int i = 0;
		SenderMsg* btrpkt = (SenderMsg*) (call radSenSenderMsg.getPayload(&pkt, sizeof(SenderMsg)));

		btrpkt -> mes_id = buffer[temp_mes_id].mes_id;
		btrpkt -> seq_num = seq_num;
		btrpkt -> node_id = TOS_NODE_ID;

//adatfeltoltes
		for(i=0; i<(DATA_LENGTH); i++) {
			if( (i+seq_num*(DATA_LENGTH)) >= MEASUREMENT_LENGTH)  	//vegere ertunk az adott meresnek
				btrpkt -> data[i] = 0;								//a maradek payload-ot nullaval toltsuk fel
			else
				btrpkt -> data[i] = buffer[temp_mes_id].data[i+seq_num*(DATA_LENGTH)];	//DATA_LENTGT=PAYLOAD_LENGHT-2
		}

		if(call radSenSenderMsg.send(1, &pkt, sizeof(SenderMsg))==SUCCESS) { // 1 - base station
			seq_num = seq_num + 1;		//sikeres kikuldes eseten 1-el novekszik a szelet szama
		}
	}

	command error_t Storage.take() 	{
		if(mes_id <=0) {
			return FAIL;	//nincs bufferben adat
		}
		post send();
		return SUCCESS;		
	}


	event void radSenSenderMsg.sendDone(message_t *msg, error_t error) {	
	if(slice_send == FALSE) {
		if(&pkt == msg && seq_num<ceil((double)MEASUREMENT_LENGTH/(DATA_LENGTH))) {	//addig kuldjuk a meres szeleteit, amig vegeig nem erunk						
			post send();
		} else {
			if(&pkt == msg && temp_mes_id < mes_id-1) {	//amig nem kuldtuk ki az osszes merest
				temp_mes_id = temp_mes_id + 1;
				seq_num = 0;			//uj meres = ujbol 0-zuk a szeletszamot
				post send();
			} else {
				if(&pkt == msg) {		//ha mar minden merest kikuldtunk
					temp_mes_id = 0;	//0-as lesz az elso meres indexe
					seq_num = 0;		//0-es csomaggal kezdi majd az ujabb kikuldesnel a send-et
					signal Storage.takeDone();
				}
			}
		}
	} else
		slice_send = FALSE;
	}

	task void delete() {
		int i, j;
		for(i = 0; i < mes_id; i++) {
			for(j = 0; j < MEASUREMENT_LENGTH; j++) {
				buffer[i].data[j] = 0;
			}
			buffer[i].mes_id = 0;
		}
		temp_mes_id = 0;
		seq_num = 0;
		mes_id = 0;
		atomic { sending = FALSE; }		//csak tesztelesnel, amikor nincs benn a commEnd metodus
		signal Storage.deleteDone();
	}

	command error_t Storage.delete() {
		post delete();
		return SUCCESS;
	}

	task void sliceSend() {
		int i;
		SenderMsg* btrpkt = (SenderMsg*) (call radSenSenderMsg.getPayload(&pkt, sizeof(SenderMsg)));
		btrpkt -> mes_id = mes_id_sS;
		btrpkt -> seq_num = slice_sS;
		btrpkt -> node_id = TOS_NODE_ID;

//adatfeltoltes
		for(i=0; i<(DATA_LENGTH); i++) {
			if( (i+slice_sS*(DATA_LENGTH)) >= MEASUREMENT_LENGTH)  	//vegere ertunk az adott meresnek
				btrpkt -> data[i] = 0;								//a maradek payload-ot nullaval toltsuk fel
			else
				btrpkt -> data[i] = buffer[mes_id_sS].data[i+slice_sS*(DATA_LENGTH)];	//DATA_LENTGT=PAYLOAD_LENGTH-3
		}

		if(call radSenSenderMsg.send(1, &pkt, sizeof(SenderMsg))==SUCCESS) { // 1 - base station
		}
	}

	command error_t Storage.getSlice(uint8_t mes_id_p, uint8_t slice_p) {
		if(mes_id <= 0) {
			return FAIL;	//nincs bufferben adat
		}
		slice_send = TRUE;
		mes_id_sS = mes_id_p;
		slice_sS = slice_p;
		post sliceSend();
		return SUCCESS;	
	}

//Send Mesure number
	task void mesNumberSend() {
		MesNumberMsg* btrpkt = (MesNumberMsg*) (call radSenMesNumberMsg.getPayload(&pkt, sizeof(MesNumberMsg)));
		btrpkt -> mes_number = mes_id;		//mennyi merest taroltunk el osszesen
		btrpkt -> node_id = TOS_NODE_ID;

		if(call radSenMesNumberMsg.send(1, &pkt, sizeof(MesNumberMsg))==SUCCESS) { // 1 - base station
		}
	}

	event void radSenMesNumberMsg.sendDone(message_t *msg, error_t error) {
		signal Storage.sendMeasurementNumberDone();
	}

	command error_t Storage.sendMeasurementNumber() {
		atomic { sending = TRUE; }	//elkezdtunk kommunikalni a bazissal
		post mesNumberSend();
		return SUCCESS;	
	}

	task void end() {
		signal Storage.commEndDone();
	}

//Communication End
	async command void Storage.commEnd() {
		atomic {
			int i, j;
			for(i = 0; i < tmp_mes_id; i++) {
				for(j = 0; j < MEASUREMENT_LENGTH; j++) {
					buffer[i].data[j] = tmp_buffer[i].data[j];
					tmp_buffer[i].data[j] = 0;
				}
				buffer[i].mes_id = tmp_buffer[i].mes_id;
				tmp_buffer[i].mes_id = 0;
			}
			mes_id = tmp_mes_id;
			tmp_mes_id = 0;
			sending = FALSE;
			post end(); 
		}				
	}
	
	default event void Storage.deleteDone() {
	}
	
	default event void Storage.takeDone() {
	}

	default event void Storage.sendMeasurementNumberDone() {
	}

	default event void Storage.commEndDone() {
	}
}
