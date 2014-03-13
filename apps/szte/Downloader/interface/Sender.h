#ifndef SENDER_H
#define SENDER_H			

#ifndef PAYLOAD_LENGTH
#define PAYLOAD_LENGTH 13		//payload merete (1 byte meres_id + 1 byte seq_num + 100 byte adat)
#endif							//PAYLOAD_LENGTH=10-re valami baja van. csomag kimenetek a vege fele 0-ra valtanak.

#ifndef DATA_LENGTH						//payload meresi adat resze
#define DATA_LENGTH PAYLOAD_LENGTH-3	//ket bajtot elfoglal mas
#endif

#ifndef MEASUREMENT_LENGTH		//meres hossza 
#define MEASUREMENT_LENGTH 40
#endif

#ifndef TOSH_DATA_LENGTH		//message.h payload merete
#define TOSH_DATA_LENGTH PAYLOAD_LENGTH	
#endif

#ifndef MAX_MEASUREMENT_NUMBER
#define MAX_MEASUREMENT_NUMBER 10
#endif

typedef nx_struct SenderMsg {
	nx_uint8_t mes_id;
	nx_uint8_t seq_num;
	nx_uint8_t data[DATA_LENGTH];
	nx_uint8_t node_id;
}SenderMsg;

typedef nx_struct MesNumberMsg {
	nx_uint8_t mes_number;		//mennyi meresi adat van
	nx_uint8_t node_id;
}MesNumberMsg;

typedef struct data_t{
    uint8_t mes_id;
	uint8_t data[MEASUREMENT_LENGTH];
}data_t;

enum{
	AM_SENDERMSG = 6,
	AM_MESNUMBERMSG = 8
};

#endif
