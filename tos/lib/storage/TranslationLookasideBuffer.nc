#include "TranslationLookasideBuffer.h"
interface TranslationLookasideBuffer{
  command void addNew(uint32_t address, uint32_t page, uint16_t filledBytes);
  command void getClosest(minmax_tlb_t *low, minmax_tlb_t *high, uint32_t searchAddress);
  command void invalid(uint32_t fromPage, uint32_t toPage);
}