#include "Storage.h"
#include "At45db.h"
#define PAGE_SIZE AT45_PAGE_SIZE
generic configuration At45dbPageLayerC(volume_id_t volume_id) {
  provides interface PageLayer;
}

implementation {

  enum {
    PAGE_ID = unique("at45db.page"),
    RESOURCE_ID = unique(UQ_AT45DB),
  };
    
  components At45dbPageLayerP, At45dbStorageManagerC, At45dbC;

  PageLayer = At45dbPageLayerP.PageLayer[PAGE_ID];

  At45dbPageLayerP.At45dbVolume[PAGE_ID] -> At45dbStorageManagerC.At45dbVolume[volume_id];  
  At45dbPageLayerP.Resource[PAGE_ID] -> At45dbC.Resource[PAGE_ID];
  At45dbPageLayerP.At45db->At45dbC;
  
}