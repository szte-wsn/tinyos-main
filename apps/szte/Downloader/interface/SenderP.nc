#include "Sender.h"

module SenderP{
  provides interface Storage;
  uses{
  	interface Boot;
	interface SplitControl;
  	interface Leds;

    interface AMSend as radSenMeasureMsg;
	interface AMSend as radSenAnnouncementMsg;
	interface Receive as radRecGetSliceMsg; 
	interface Receive as radRecCommandMsg; 
	interface Receive as radRecFreeMsg;
  }
}

implementation {	
//VALTOZOK
	norace data_t buffer[MAX_MEASUREMENT_NUMBER];
	norace uint8_t read, write, keep;
	norace uint8_t write_send; 	//kuldes elott eltaroljuk, hogy hova mutat a write
	norace uint8_t data_number;
	norace uint8_t mes_id; 
	norace bool full;
	uint8_t seq_num;			//hanyadik szeletet kuldjuk ki
	norace bool sending;		//ha kuldunk TRUE, egyebkent FALSE
	bool slice_sending;			//ha csak egy slice-t kuldunk ki
	message_t pkt;

//DEFINIALATLAN METODUSOK
	bool send(uint8_t a_mes_id, uint8_t a_slice_id);	//read-et a write-ig novelem
	task void stop();						//keep-et a read-ig novelem
	task void sendControl();

//BOOT
	event void Boot.booted() {
		read = 0;
		write = 0;
		keep = 0;			//azert ennyi, hogy az elso store meghivasnal ne dobjon failt, mivel ha 0 lenne, akkor failt dobna vissza egybol a store
		write_send = 0;
		data_number = 0;
		mes_id = 0;
		seq_num = 0;
		sending = FALSE;
		slice_sending = FALSE;
		full = FALSE;
		call SplitControl.start();		
	}	

	event void SplitControl.startDone(error_t error) {
	}

	event void SplitControl.stopDone(error_t error) {
	}	

//ANNOUNCEMENT
	task void AnnouncementSend() {
		AnnouncementMsg* btrpkt = (AnnouncementMsg*) (call radSenAnnouncementMsg.getPayload(&pkt, sizeof(AnnouncementMsg)));
		data_number = full==FALSE?((uint8_t)(write-keep)%MAX_MEASUREMENT_NUMBER):MAX_MEASUREMENT_NUMBER;		//mert ha kezdetben keep = 0, es ha a write beirt 4 adatot, akkor visszater a write 0-ba, es megegyeznek, es az jonne ki, hogy 0-0%4 vagyis nincs a tarban adat
		btrpkt -> mes_number = data_number;		//mennyi merest taroltunk el osszesen
		if(FALSE == sending) {
				write_send = write;
		}
		call radSenAnnouncementMsg.send(AM_BROADCAST_ADDR, &pkt, sizeof(AnnouncementMsg));
	}	

//STORE
	async command error_t Storage.store(uint8_t* data) {		//write-ot novelem egyel
		atomic {
			uint16_t i;
			if(full) {	
				return ENOMEM;	//tele a buffer
			}
			for(i = 0; i < MEASUREMENT_LENGTH; i++) {
				buffer[write].data[i] = data[i];	
			}
			buffer[write].mes_id = mes_id;	
			mes_id++;
			write = write<MAX_MEASUREMENT_NUMBER-1?write+1:0;
			full = (keep == write);
		}
		post AnnouncementSend();		//kikuldjuk, hogy mennyi adatunk van
		return SUCCESS;
	}

//SEND
	error_t send(uint8_t a_mes_id, uint8_t a_seq_num) {
		uint16_t i;
		MeasureMsg* btrpkt = (MeasureMsg*) (call radSenMeasureMsg.getPayload(&pkt, sizeof(MeasureMsg)));

		btrpkt -> mes_id = a_mes_id;
		btrpkt -> seq_num = a_seq_num;
		btrpkt -> slice_width = (a_seq_num+1)*((DATA_LENGTH))>MEASUREMENT_LENGTH?MEASUREMENT_LENGTH-(a_seq_num*(DATA_LENGTH)):(DATA_LENGTH);
		for(i=0; i<btrpkt -> slice_width; i++) 
			btrpkt -> data[i] = buffer[read].data[i+(a_seq_num*(DATA_LENGTH))];	
		return call radSenMeasureMsg.send(AM_BROADCAST_ADDR, &pkt, sizeof(MeasureMsg));
	}

//SENDCONTROL
	task void sendControl() {
		if(read != write || TRUE == full) {	//ha full-t nem ellenorizem, akkor megeshet, hogy read = write es nem menne tovabb, pl legelso kivitelnel. write = 0, mivel egyszer tullepet mar a write (tele a buffer), es elejeben a read is 0
			if((uint16_t)(seq_num+1)*(DATA_LENGTH) <= MEASUREMENT_LENGTH + (DATA_LENGTH)) {	//egy teljes meres kikuldese				
				while(send(buffer[read].mes_id, seq_num) != SUCCESS);					
			} else {		//minden szeletet kikuldtunk a meresbol
				read = read<MAX_MEASUREMENT_NUMBER-1?read+1:0;	
				seq_num = 0;	//azert ide tettem ezeket, hogy nehogy eloforduljon olyan eset, hogy a stop-ot a mote 2x kapja meg rovid idon belul, mert ha ez megtortenne es ez a ket sor a stop-ban lenne, akkor kitorolnenk egy meg el nem kuldott merest
			}
		}
	}

//STOP
	task void stop() {		//ha nem kapunk stoppot, akkor tovabbi mereseket se kuldunk ki, mert nem tudjuk hogy az adott meresbol a bazis minden szeletet megkapott-e
		keep = read;
		full = FALSE;
		post AnnouncementSend();
		if(TRUE == sending) {
			post sendControl();
		}
	}

//UZENETEK KULDES
	event void radSenMeasureMsg.sendDone(message_t *msg, error_t error) {	
		if(!slice_sending) {
			seq_num++;
			post sendControl();
		} else {
			slice_sending = FALSE;
		}
	}

	event void radSenAnnouncementMsg.sendDone(message_t *msg, error_t error) {
	}

//UZENETEK VETEL
	event message_t* radRecCommandMsg.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(CommandMsg)) {		
			CommandMsg* btrpkt = (CommandMsg*) (call radSenMeasureMsg.getPayload(msg, sizeof(CommandMsg)));
			if(btrpkt -> node_id_start == TOS_NODE_ID) {	//elkezd adni
				atomic { sending = TRUE; } 	
				post sendControl();	
			}	
			if(btrpkt -> node_id_stop == TOS_NODE_ID) {		//vege az adasnak
				atomic { sending = FALSE; }			
				post stop();
			}
		}
		return msg;
	}


	event message_t* radRecGetSliceMsg.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(GetSliceMsg)) {
			GetSliceMsg* btrpkt = (GetSliceMsg*) (call radSenMeasureMsg.getPayload(msg, sizeof(GetSliceMsg)));
			if(TOS_NODE_ID == btrpkt -> node_id) {		//egy bizonyos szeletet kerunk le
				slice_sending = TRUE;
				send(btrpkt -> mes_id, btrpkt -> slice); 
			}
		}
		return msg;
	}


	event message_t* radRecFreeMsg.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(FreeMsg)) {
			FreeMsg* btrpkt = (FreeMsg*) (call radSenMeasureMsg.getPayload(msg, sizeof(FreeMsg)));
			if(TOS_NODE_ID == btrpkt -> node_id) {		
				post stop();
			}
		}
		return msg;
	}
}
