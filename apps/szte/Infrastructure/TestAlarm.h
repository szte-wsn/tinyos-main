#ifndef TEST_ALARM_H
#define TEST_ALARM_H

#include "InfrastructureSettings.h"
#define WAVE_MESSAGE_LENGTH 80
#define BUFFER_LEN 480

enum {
  AM_SYNCMSG = 6,
  AM_WAVE_MESSAGE_T = 7,
  //just for mig
  AM_REAL_SYNC_MESSAGE_T = 0x3d,
  BUFFER_LEN_MIG = BUFFER_LEN,
};

typedef nx_struct wave_message_t{
  nx_uint8_t whichWaveform;
  nx_uint8_t whichPartOfTheWaveform;
  nx_uint8_t data[WAVE_MESSAGE_LENGTH];
} wave_message_t;

//just for mig
typedef nx_struct real_sync_message_t{
  nx_uint8_t frame;
  nx_uint8_t phaseRef[NUMBER_OF_RX];
  nx_uint16_t freq[NUMBER_OF_RX];
  nx_uint8_t phase[NUMBER_OF_RX];
  nx_uint8_t min[NUMBER_OF_RX];
  nx_uint8_t max[NUMBER_OF_RX];
  nx_uint8_t originalAm;
  nx_uint32_t timesync;
} real_sync_message_t;

#endif
