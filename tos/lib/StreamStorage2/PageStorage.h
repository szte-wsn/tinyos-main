#ifndef PAGESTORAGE_H
#define PAGESTORAGE_H

#if defined(PLATFORM_EPIC) || defined(PLATFORM_IRIS) || defined(PLATFORM_MICA) || defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT) || defined(PLATFORM_MICAZ) || defined(PLATFORM_MULLE) || defined(PLATFORM_TELOSA) || defined(PLATFORM_TINYNODE)
  #define AT45DB
  #include "Storage.h"
 // #include "HplAt45db_chip.h"
  #define PAGE_SIZE AT45_PAGE_SIZE
  #define EMPTY_BYTE 0xff
  #elif defined(PLATFORM_TELOSB) || defined(PLATFORM_UCDUAL) || defined(PLATFORM_UCMINI) || defined(PLATFORM_Z1) || defined(PLATFORM_UCMINI) || defined(PLATFORM_UCPROTONA) || defined(PLATFORM_UCPROTONB) || defined(PLATFORM_GRAINPATROL) || defined(PLATFORM_UCBASE) || defined(PLATFORM_UCBASEDRD)
  #include "Stm25PageStorage.h"
#endif



#endif