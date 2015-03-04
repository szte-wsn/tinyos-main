interface MeasureWave{
  command void changeData(uint8_t *data, uint16_t len);
  command uint16_t getPeriod();
	command uint8_t getPhase();
  command uint8_t getMinAmplitude();
	command uint8_t getMaxAmplitude();
	command uint8_t getPhaseRef();
	command uint8_t getRssi1();
	command uint8_t getRssi2();
	command void filter();
}