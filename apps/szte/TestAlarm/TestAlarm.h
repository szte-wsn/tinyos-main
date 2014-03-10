#ifndef TEST_ALARM_H
#define TEST_ALARM_H

typedef nx_struct uzenet {
  nx_uint8_t funcid;
  nx_uint32_t ido;
} uzenet_t;

typedef nx_struct config_msg_t {
	//first Test
  	nx_uint16_t T1sender1ID;
	nx_uint16_t T1sender2ID;
	nx_uint8_t T1channel :5;
	nx_uint8_t T1mode 	 :1;
	nx_uint8_t			 :2;
	nx_uint8_t T1trim1   :4;
	nx_uint8_t T1trim2   :4;
	nx_uint32_t T1sender_wait;
	nx_uint32_t T1sender_send;
	nx_uint32_t T1receiver_wait;
	//second Test
	nx_uint16_t T2sender1ID;
	nx_uint16_t T2sender2ID;
	nx_uint8_t T2channel :5;
	nx_uint8_t T2mode 	 :1;
	nx_uint8_t			 :2;
	nx_uint8_t T2trim1   :4;
	nx_uint8_t T2trim2   :4;
	nx_uint32_t T2sender_wait;
	nx_uint32_t T2sender_send;
	nx_uint32_t T2receiver_wait;
	//third Test
	nx_uint16_t T3sender1ID;
	nx_uint16_t T3sender2ID;
	nx_uint8_t T3channel :5;
	nx_uint8_t T3mode 	 :1;
	nx_uint8_t			 :2;
	nx_uint8_t T3trim1   :4;
	nx_uint8_t T3trim2   :4;
	nx_uint32_t T3sender_wait;
	nx_uint32_t T3sender_send;
	nx_uint32_t T3receiver_wait;
} config_msg_t;

enum {
  AM_RADIOMSG = 6,
};

#endif
