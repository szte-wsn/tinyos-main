#ifndef __INFRASTRUCTURESETTINGS_H__
#define __INFRASTRUCTURESETTINGS_H__

enum {
	TX1 = 0, //sendWave 1
	TX2 = 1, //sendWave 1
	RX = 2, //sampleRSSI
	SSYN=3, //sends sync message
	RSYN=4, //waits for sync message
	DEB = 5,
	NTRX = 6,
	NDEB = 7,
	W1 = 8,
	W10 = 9,
	W100 = 10,
	W1K = 11,
};

#define NUMBER_OF_INFRAST_NODES 4

#if NUMBER_OF_INFRAST_NODES == 4
	#ifndef SEND_WAVEFORM
		#define NUMBER_OF_SLOTS 16
		#define NUMBER_OF_RX 6
		const_uint8_t motesettings[NUMBER_OF_INFRAST_NODES][NUMBER_OF_SLOTS] = {
			//  0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15
			{RSYN,  TX1,  TX1,  TX1, SSYN,  TX1,  TX1,   RX, RSYN,   RX,  TX1,   RX, RSYN,   RX,   RX,   RX},
			{RSYN,   RX,   RX,   RX, RSYN,  TX2,  TX2,  TX1, SSYN,  TX1,   RX,  TX1, RSYN,   RX,  TX1,   RX},
			{RSYN,  TX2,   RX,   RX, RSYN,   RX,   RX,   RX, RSYN,  TX2,  TX2,  TX2, SSYN,  TX1,   RX,  TX1},
			{SSYN,   RX,  TX2,  TX2, RSYN,   RX,   RX,  TX2, RSYN,   RX,   RX,   RX, RSYN,  TX2,  TX2,  TX2}
		};
	#else
		#define NUMBER_OF_SLOTS 52
		#define NUMBER_OF_RX 6
		const_uint8_t motesettings[NUMBER_OF_INFRAST_NODES][NUMBER_OF_SLOTS] = {
			//  0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19    20    21    22    23    24    25    26    27    28    29    30    31    32    33    34    35    36    37    38    39    40    41    42    43    44    45    46    47    48    49    50    51
			{SSYN,  TX1,  TX1,   RX, RSYN,  TX1,  TX1,   RX, RSYN,  TX1,  TX1,   RX, RSYN,   RX,   RX,   RX, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB},
			{RSYN,   RX,   RX,   RX, SSYN,  TX2,   RX,  TX1, RSYN,  TX2,   RX,  TX1, RSYN,  TX1,  TX1,   RX, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB},
			{RSYN,  TX2,   RX,  TX1, RSYN,   RX,   RX,   RX, SSYN,   RX,  TX2,  TX2, RSYN,  TX2,   RX,  TX1, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB},
			{RSYN,   RX,  TX2,  TX2, RSYN,   RX,  TX2,  TX2, RSYN,   RX,   RX,   RX, SSYN,   RX,  TX2,  TX2, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB}
		};
	#endif
#elif NUMBER_OF_INFRAST_NODES == 5
	//TODO
#endif

#endif
