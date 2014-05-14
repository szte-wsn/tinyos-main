#ifndef SENDER_H
#define SENDER_H			

#ifndef DATA_LENGTH					//payload meresi adat resze
#define DATA_LENGTH TOSH_DATA_LENGTH-3	
#endif

#ifndef MEASUREMENT_LENGTH			//meres hossza 
#define MEASUREMENT_LENGTH 1000
#endif

#ifndef MAX_MEASUREMENT_NUMBER
#define MAX_MEASUREMENT_NUMBER 4
#endif

#ifndef DELETE_MES_NUMBER
#define DELETE_MES_NUMBER 2
#endif

typedef nx_struct MeasureMsg {
	nx_uint8_t mes_id;				//packet_id - hanyadik csomagrol van szo
	nx_uint8_t seq_num;				//hanyadik szeletrol van szo a meresen belul
	nx_uint8_t data[DATA_LENGTH];
	nx_uint8_t slice_width;			//az adott szeletbol megmondja, hogy mennyi mennyi a valos
}MeasureMsg;

typedef nx_struct AnnouncementMsg {
	nx_uint8_t mes_number;		//hany csomag van a bufferben
}AnnouncementMsg;

typedef nx_struct GetSliceMsg {		//elveszett csomag eseten
	nx_uint8_t slice;				//melyik szelet
	nx_uint8_t mes_id;				//melyik meresnek
	nx_uint16_t node_id;
}GetSliceMsg;

typedef nx_struct CommandMsg {
	nx_uint16_t node_id_start;
	nx_uint16_t node_id_stop;
	nx_uint8_t free[DELETE_MES_NUMBER];		//az utolso negy csomagot, amit ki kell, hogy toroljon, kitorli. Azert tettem bele, hogy ne kelljen az utolso csomag vegen egy free-t es egy commandMsg-t is kuldenie egymas utan
}CommandMsg;

typedef nx_struct FreeMsg {
	nx_uint8_t free[DELETE_MES_NUMBER];		//az utolso negy csomagot, amit ki kell, hogy toroljon, kitorli
	nx_uint16_t node_id;
}FreeMsg;

typedef struct data_t{
    uint8_t mes_id;
	uint8_t data[MEASUREMENT_LENGTH];
}data_t;

enum{
	AM_MEASUREMSG = 6,
	AM_GETSLICEMSG = 7,
	AM_ANNOUNCEMENTMSG = 8,
	AM_COMMANDMSG = 9,
	AM_FREEMSG = 11,
	TIMER_PERIOD_MILLI = 1000
};

#endif
