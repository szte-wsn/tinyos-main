interface MeasureWave{
  command uint16_t getPeriod(uint8_t *data, uint16_t len, uint8_t *average);
  command uint16_t getPhase(uint8_t *data, uint16_t len, uint16_t period, uint8_t zeropoint);
}