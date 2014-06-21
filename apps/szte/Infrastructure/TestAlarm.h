#ifndef TEST_ALARM_H
#define TEST_ALARM_H

typedef nx_struct config_msg_t {
	nx_uint16_t Tsender1ID;
	nx_uint16_t Tsender2ID;
	nx_uint8_t Tchannel :5;
	nx_uint8_t Tmode 	:1;
	nx_uint8_t not_used	:2;
	nx_uint8_t Ttrim1   :4;
	nx_uint8_t Ttrim2   :4;
	nx_uint32_t Tsender_wait;
	nx_uint32_t Tsender_send;
	nx_uint32_t Treceiver_wait;
} config_msg_t;

typedef nx_struct sync_message_t{
	nx_uint8_t frame;
} sync_message_t;

enum {
	AM_RADIOMSG = 6,
};

enum{
	AM_RSSIMESSAGE_T = 10,
	AM_RSSIDATADONE_T = 12,
	MSG_BUF_LEN = 16,
};

typedef nx_struct rssiMessage_t{
	nx_uint16_t index;
	nx_uint8_t data[MSG_BUF_LEN];
} rssiMessage_t;

typedef nx_struct rssiDataDone_t{
} rssiDataDone_t;

#endif
