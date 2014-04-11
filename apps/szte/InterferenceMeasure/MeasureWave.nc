interface MeasureWave{
	command uint16_t getStart(uint8_t *data, uint16_t len, uint8_t amplitudeThreshold, uint8_t timeThreshold);
	command uint16_t getPeriod(uint8_t *data, uint16_t len, uint8_t *average);
	command uint16_t getPhase(uint8_t *data, uint16_t len, uint16_t offset, uint16_t period, uint8_t zeropoint);
	command void filter(uint8_t *data, uint16_t len, uint8_t filterlen, uint8_t count);
}