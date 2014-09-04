#ifndef __PAGE_META_LAYER_H__
#define __PAGE_META_LAYER_H__

typedef nx_struct metadata_t{
  nx_uint16_t filledBytes:16;
  nx_uint32_t startAddress;
} metadata_t;

#endif
