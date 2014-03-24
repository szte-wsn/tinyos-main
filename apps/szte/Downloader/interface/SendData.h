#include "Sender.h"

#ifndef SENDDATA_H
#define SENDDATA_H


typedef nx_struct GetSliceMsg {		//elveszett csomag eseten
	nx_uint8_t slice;		//melyik szelet
	nx_uint8_t mes_id;		//melyik meresnek
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


enum {
	TIMER_PERIOD_MILLI=1000,
	AM_GETSLICEMSG = 7,
	AM_COMMANDMSG = 9,
	AM_FREEMSG = 11
};

#endif
