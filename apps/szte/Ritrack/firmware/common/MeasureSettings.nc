interface MeasureSettings{
	async command uint8_t getChannel(uint8_t slotType, uint8_t slotNumber);
	async command uint8_t getTxPower(uint8_t slotType, uint8_t slotNumber);
	async command uint8_t getTrim(uint8_t slotType, uint8_t slotNumber);
	async command uint16_t getSendTime();

	async command uint16_t getDelay(uint8_t slotType);
	async command uint32_t getSlotTime(uint8_t slotType);
}