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
	message_t pkt;

//DEFINIALATLAN METODUSOK
	bool send(uint8_t a_mes_id, uint8_t a_slice_id);	//read-et a write-ig novelem
	task void stop();						//keep-et a read-ig novelem
	task void initalize();
	task void sendControl();

	task void initalize() { //FIXME ez ne legyen taskban
		read = 0;
		write = 0;
		keep = 0;			//azert ennyi, hogy az elso store meghivasnal ne dobjon failt, mivel ha 0 lenne, akkor failt dobna vissza egybol a store
		write_send = 0;
		data_number = 0;
		mes_id = 0;
		seq_num = 0;
		sending = FALSE;
		full = FALSE;
	}
//BOOT
	event void Boot.booted() {
		post initalize();		
		call SplitControl.start();		
	}	

	event void SplitControl.startDone(error_t error) {
	}

	event void SplitControl.stopDone(error_t error) {
	}	

//ANNOUNCEMENT
	task void AnnouncementSend() {
		AnnouncementMsg* btrpkt = (AnnouncementMsg*) (call radSenAnnouncementMsg.getPayload(&pkt, sizeof(AnnouncementMsg)));
		btrpkt -> mes_number = data_number;		//mennyi merest taroltunk el osszesen
		//FIXME write_send kezelése
		if(call radSenAnnouncementMsg.send(1, &pkt, sizeof(AnnouncementMsg))==SUCCESS) { // 1 - base station //FIXME broadcast
		}
	}	

//STORE
	async command error_t Storage.store(uint8_t* data) {		//write-ot novelem egyel
		atomic {
			uint16_t i;
			if(full) {	
				return FAIL;	//tele a buffer //FIXME inkább ENOMEM
			}
			for(i = 0; i < MEASUREMENT_LENGTH; i++) {
				buffer[write].data[i] = data[i];	
			}
			buffer[write].mes_id = mes_id;
			if(FALSE == sending) {
				write_send = write; //FIXME ez nem kell, elég küldésnél foglalkozni vele
			}		
			mes_id = mes_id<=255?mes_id+1:0; //FIXME <= helyett <, de egyébként is minek?
			data_number++;	//FIXME ez kicsit felesleges: data_number == (write - keep)%MAX_MEASUREMENT_NUMBER Legalábbis azt hiszem
			write = write<MAX_MEASUREMENT_NUMBER-1?write+1:0;
			if(keep == write) {
				full = TRUE; //FIXME szintén kicsit felesleges. full == (keep == write)
			}
		}
		post AnnouncementSend();		//kikuldjuk, hogy mennyi adatunk van
		return SUCCESS;
	}

//SEND
	bool send(uint8_t a_mes_id, uint8_t a_seq_num) {
		uint16_t i;
		MeasureMsg* btrpkt = (MeasureMsg*) (call radSenMeasureMsg.getPayload(&pkt, sizeof(MeasureMsg)));

		btrpkt -> mes_id = a_mes_id;
		btrpkt -> seq_num = a_seq_num;
		btrpkt -> slice_width = (a_seq_num+1)*((DATA_LENGTH))>MEASUREMENT_LENGTH?MEASUREMENT_LENGTH-(a_seq_num*(DATA_LENGTH)):(DATA_LENGTH);
		for(i=0; i<btrpkt -> slice_width; i++) 
			btrpkt -> data[i] = buffer[read].data[i+(a_seq_num*(DATA_LENGTH))];	
		if(call radSenMeasureMsg.send(1, &pkt, sizeof(MeasureMsg))==SUCCESS) //FIXME nyugodtan visszaadhatod az error_t-t is...
			return TRUE;	
		else
			return FALSE;
	}

//SENDCONTROL
	task void sendControl() {
		if(read != write || TRUE == full) {	//ha full = TRUE, akkor megeshet, hogy read = write es nem menne tovabb //FIXME miért?
			if((uint16_t)(seq_num+1)*(DATA_LENGTH) <= MEASUREMENT_LENGTH + (DATA_LENGTH)) {	//egy teljes meres kikuldese				
				send(buffer[read].mes_id, seq_num);				//FIXME ha hibával tér vissza, leáll az egész
			} 
		}
	}

//STOP
	task void stop() {	
		uint8_t keep_tmp;
		read = read<MAX_MEASUREMENT_NUMBER-1?read+1:0;
		seq_num = 0;
		keep_tmp = keep;
    //FIXME Ha nem kell a data_number és a full, akkor itt elég a keep = read;
		while(keep!=read) {		
			data_number--;
			keep = keep<MAX_MEASUREMENT_NUMBER-1?keep+1:0;
		}
		if(TRUE == full && keep_tmp != keep) {		//keep valtozott, azt jelenti, hogy felszabadult valamennyi hely
			full = FALSE;
		}
		post AnnouncementSend(); //FIXME csak ha van adat
		if(TRUE == sending) {
			post sendControl();
		}
	}

//UZENETEK KULDES
	event void radSenMeasureMsg.sendDone(message_t *msg, error_t error) {	
			seq_num++;	
			post sendControl();
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
			if(TOS_NODE_ID == btrpkt -> node_id) {		//adatot kerunk le
				send(btrpkt -> mes_id, btrpkt -> slice); //FIXME mindent elküld a slice után, a sendDone-ban le kellene kezelni, hogy slice módban van.
			}
		}
		return msg;
	}


	event message_t* radRecFreeMsg.receive(message_t* msg, void* payload, uint8_t len) {
		if(len == sizeof(FreeMsg)) {
			FreeMsg* btrpkt = (FreeMsg*) (call radSenMeasureMsg.getPayload(msg, sizeof(FreeMsg)));
			if(TOS_NODE_ID == btrpkt -> node_id) {		//mindent lekert az adott meresbol
				post stop();
			}
		}
		return msg;
	}
}
