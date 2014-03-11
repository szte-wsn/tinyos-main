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

enum {
  AM_RADIOMSG = 6,
};

#endif
