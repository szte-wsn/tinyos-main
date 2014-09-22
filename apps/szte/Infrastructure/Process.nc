interface Process{
  command void changeData(uint8_t *data, uint16_t len, uint8_t amplitudeThreshold, uint8_t leadTime);
  command uint16_t getPeriod();
	command uint8_t getPhase();
  command uint8_t getMinAmplitude();
	command uint8_t getMaxAmplitude();
	command uint8_t getStartPoint();
}
