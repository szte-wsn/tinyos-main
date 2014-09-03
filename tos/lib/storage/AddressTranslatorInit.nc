interface AddressTranslatorInit{
  command void init(uint32_t minAddressPage, uint32_t maxAddressPage, uint32_t maxStartAddress, uint16_t maxFilledByte);
}