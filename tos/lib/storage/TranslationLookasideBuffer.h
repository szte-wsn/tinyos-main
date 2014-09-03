#ifndef __TRANSLATION_LOOKASIDE_BUFFER__
#define __TRANSLATION_LOOKASIDE_BUFFER__

typedef struct minmax_tlb_t{
  uint32_t address;
  uint32_t page;
  uint16_t bytesFilled;
  bool valid;
}minmax_tlb_t;

#endif