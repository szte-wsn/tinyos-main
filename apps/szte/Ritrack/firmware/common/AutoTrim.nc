interface AutoTrim{
	command void processSchedule();
	command void processSyncMessage(uint8_t senderId, void* payload);
	async command uint8_t getTrim(uint8_t slotId_in);
}
