#ifndef __INTERFERENCMSG_H__
#define __INTERFERENCMSG_H__
enum{
	AM_RSSIMESSAGE_T = 10,
	AM_COMMANDMESSAGE_T = 11,
	MSG_BUF_LEN = 16,
};

typedef nx_struct rssiMessage_t{
	nx_uint32_t time;
	nx_uint16_t index;
	nx_uint8_t data[MSG_BUF_LEN];
} rssiMessage_t;

typedef nx_struct commandMessage_t{
	nx_uint16_t cw[2];
	nx_uint8_t cwMode[2];
	nx_uint32_t cwLength;
	nx_uint32_t waitBeforeCw;
	nx_uint32_t waitBeforeMeasure;
} commandMessage_t;

#endif