interface RssiMonitor{
  async command uint32_t start(void* buffer, uint16_t len);
}