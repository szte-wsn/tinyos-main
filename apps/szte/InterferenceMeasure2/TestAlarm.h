#ifndef TEST_ALARM_H
#define TEST_ALARM_H

typedef nx_struct config_msg_t {
	nx_uint16_t Tsender1ID;
	nx_uint16_t Tsender2ID;
	nx_uint8_t Tchannel;
	nx_int8_t Tfinetune1;
	nx_int8_t Tfinetune2;
	nx_uint8_t Tpower1;
	nx_uint8_t Tpower2;
	nx_uint32_t Tsender_wait;
	nx_uint16_t measureId;
} config_msg_t;

enum {
	AM_RADIOMSG = 20,
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
