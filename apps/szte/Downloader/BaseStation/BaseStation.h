#ifndef BASESTATION_H
#define BASESTATION_H

#ifndef TOSH_DATA_LENGTH			//azert kellett itt definialnom ezt, mert a fordito kiirta, hogy nincs definialva
#define TOSH_DATA_LENGTH 110		//esetleg makefajlba betett CFLAG TOSH_DATA_LENGHT-et felhasznalni valahogy?
#endif


#ifndef DATA_LENGTH					//payload meresi adat resze
#define DATA_LENGTH TOSH_DATA_LENGTH-6			
#endif

#ifndef MEASUREMENT_LENGTH			//meres hossza 
#define MEASUREMENT_LENGTH 1019
#endif

#ifndef MAX_MEASUREMENT_NUMBER
#define MAX_MEASUREMENT_NUMBER 4
#endif

#ifndef DELETE_MES_NUMBER
#define DELETE_MES_NUMBER 2
#endif

typedef nx_struct MeasureMsg {
	nx_uint16_t mes_width;			//a teljes meres hossza
	nx_uint16_t mes_id;				//packet_id - hanyadik csomagrol van szo
	nx_uint8_t seq_num;				//hanyadik szeletrol van szo a meresen belul
	nx_uint8_t data[DATA_LENGTH];
	nx_uint8_t slice_width;
}MeasureMsg;

typedef nx_struct GetSliceMsg {		//elveszett csomag eseten
	nx_uint8_t slice;				//melyik szelet
	nx_uint16_t mes_id;				//melyik meresnek
	nx_uint16_t node_id;
}GetSliceMsg;

typedef nx_struct AnnouncementMsg {
	nx_uint8_t mes_number;			//hany csomag van a bufferben
}AnnouncementMsg;

typedef nx_struct CommandMsg {
	nx_uint16_t node_id_start;
	nx_uint16_t node_id_stop;
	nx_uint8_t free[DELETE_MES_NUMBER];	
}CommandMsg;

typedef nx_struct FreeMsg {
	nx_uint8_t free[DELETE_MES_NUMBER];		//az utolso negy csomagot, amit ki kell, hogy toroljon, kitorli
	nx_uint16_t node_id;
}FreeMsg;

typedef struct data_t{
    uint16_t mes_id;
	uint8_t data[MEASUREMENT_LENGTH];
}data_t;


enum{
	AM_MEASUREMSG = 6,
	AM_GETSLICEMSG = 7,
	AM_ANNOUNCEMENTMSG = 8,
	AM_COMMANDMSG = 9,
	AM_FREEMSG = 11
};

#endif
