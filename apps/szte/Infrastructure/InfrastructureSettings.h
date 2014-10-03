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
		#define NUMBER_OF_SLOTS 20
		#define NUMBER_OF_RX 6
		const_uint8_t motesettings[NUMBER_OF_INFRAST_NODES][NUMBER_OF_SLOTS] = {
			//  0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19
			{RSYN,  TX1,  TX1,  TX1,  W10, SSYN,  TX1,  TX1,   RX,  W10, RSYN,   RX,  TX1,   RX,  W10, RSYN,   RX,   RX,   RX,  W10},\
			{RSYN,   RX,   RX,   RX,  W10, RSYN,  TX2,  TX2,  TX1,  W10, SSYN,  TX1,   RX,  TX1,  W10, RSYN,   RX,  TX1,   RX,  W10},\
			{RSYN,  TX2,   RX,   RX,  W10, RSYN,   RX,   RX,   RX,  W10, RSYN,  TX2,  TX2,  TX2,  W10, SSYN,  TX1,   RX,  TX1,  W10},\
			{SSYN,   RX,  TX2,  TX2,  W10, RSYN,   RX,   RX,  TX2,  W10, RSYN,   RX,   RX,   RX,  W10, RSYN,  TX2,  TX2,  TX2,  W10}\
		};
	#else
		#define NUMBER_OF_SLOTS 56
		#define NUMBER_OF_RX 6
		const_uint8_t motesettings[NUMBER_OF_INFRAST_NODES][NUMBER_OF_SLOTS] = {
			//  0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19    20    21    22    23    24    25    26    27    28    29    30    31    32    33    34    35    36    37    38    39    40    41    42    43    44    45    46    47    48    49    50    51    52    53    54    55
			{SSYN,  TX1,  TX1,   RX,  W10, RSYN,  TX1,  TX1,   RX,  W10, RSYN,  TX1,  TX1,   RX,  W10, RSYN,   RX,   RX,   RX,  W10, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB},\
			{RSYN,   RX,   RX,   RX,  W10, SSYN,  TX2,   RX,  TX1,  W10, RSYN,  TX2,   RX,  TX1,  W10, RSYN,  TX1,  TX1,   RX,  W10, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB},\
			{RSYN,  TX2,   RX,  TX1,  W10, RSYN,   RX,   RX,   RX,  W10, SSYN,   RX,  TX2,  TX2,  W10, RSYN,  TX2,   RX,  TX1,  W10, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB},\
			{RSYN,   RX,  TX2,  TX2,  W10, RSYN,   RX,  TX2,  TX2,  W10, RSYN,   RX,   RX,   RX,  W10, SSYN,   RX,  TX2,  TX2,  W10, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, RSYN, NDEB, NDEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB, SSYN,  DEB,  DEB}\
		};
	#endif

//for processing debug it falls out of sync!
// 		#define NUMBER_OF_SLOTS 7
// 		#define NUMBER_OF_RX 1
// 		const_uint8_t motesettings[NUMBER_OF_INFRAST_NODES][NUMBER_OF_SLOTS] = {
// 			//  0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15    16    17    18    19
// 			{SSYN,   RX,  W10,  W10,  DEB,  W10,  W10},
// 			{RSYN,  TX1,  W10,  W10, NDEB,  W10,  W10},
// 			{RSYN,  TX2,  W10,  W10, NDEB,  W10,  W10},
// 			{RSYN, NTRX,  W10,  W10, NDEB,  W10,  W10}
// 		};
#elif NUMBER_OF_INFRAST_NODES == 5
	//TODO
#endif

#endif
