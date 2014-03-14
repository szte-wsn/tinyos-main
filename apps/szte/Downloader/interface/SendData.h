#include "Sender.h"

#ifndef SENDDATA_H
#define SENDDATA_H


typedef nx_struct GetSliceMsg {		//elveszett csomag eseten
	nx_uint8_t slice;		//melyik szelet
	nx_uint8_t mes_id;		//melyik meresnek
	nx_uint8_t node_id;
}GetSliceMsg;

typedef nx_struct CommandMsg {
	nx_uint8_t node_id_start;
	nx_uint8_t node_id_stop;
}CommandMsg;

typedef struct LoginMoteMsg{
	uint8_t node_id;
}LoginMoteMsg;


enum {
	TIMER_PERIOD_MILLI=1000,
	TIMER_LOGIN_MILLI=3000,
	AM_GETSLICEMSG = 7,
	AM_COMMANDMSG = 9,
	AM_LOGINMOTEMSG = 10
//	TIMER_WAIT_FOR_REQ=2000,
};

#endif
