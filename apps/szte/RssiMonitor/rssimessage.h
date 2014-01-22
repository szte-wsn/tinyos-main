#ifndef __RSSIMESSAGE_H__
#define __RSSIMESSAGE_H__
enum{
	AM_RSSIMESSAGE = 10,
	MSG_BUF_LEN = 16,
};

typedef nx_struct rssiMessage{
	nx_uint16_t index;
	nx_uint8_t data[MSG_BUF_LEN];
} rssiMessage;

#endif