interface AcousticInterrupt{
	command error_t set(uint8_t amplification, uint8_t threshold, uint16_t deprell);
	event void setDone(error_t err, uint8_t amplification, uint8_t threshold, uint16_t deprell);
	async command error_t enable();
	async command error_t disable();
	async event void fired();
}