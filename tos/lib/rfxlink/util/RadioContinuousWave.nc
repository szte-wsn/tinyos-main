interface RadioContinuousWave {
  async command error_t sendWave(uint8_t channel, int8_t tune, uint8_t power, uint16_t time);
  async command error_t sampleRssi(uint8_t channel, uint8_t *buffer, uint16_t length, uint16_t *time);
  async command uint32_t convertTime(uint32_t fromTime);
}