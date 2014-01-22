interface RssiMonitor{
  async command error_t start(void* buffer, uint16_t len);
}