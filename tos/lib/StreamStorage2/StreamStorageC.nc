generic configuration StreamStorageC(volume_id_t vol_id, bool circular, uint8_t tlbSize, uint8_t bufferNum){
  provides interface StreamStorageErase;
  provides interface StreamStorageRead;
  provides interface StreamStorageWrite;
  provides interface SplitControl;
}
implementation{
  components new Stm25pPageLayerC(vol_id) as PageLayerC;
  components new PageAllocatorLayerC();
  components new PageBufferLayerC(bufferNum);
  components new PageMetaLayerC();
  components new AddressTranslatorLayerC(circular);//init
  components new TranslationLookasideBufferC(tlbSize);
  components new StreamStorageLayerC();
  components new StorageInitC();
  
  StreamStorageErase = StreamStorageLayerC;
  StreamStorageRead = StreamStorageLayerC;
  StreamStorageWrite = StreamStorageLayerC;
  SplitControl = StorageInitC;
  
  PageAllocatorLayerC.PageLayer -> PageLayerC;
  
  PageBufferLayerC.PageAllocator -> PageAllocatorLayerC;
  
  PageMetaLayerC.PageBuffer -> PageBufferLayerC;
  
  AddressTranslatorLayerC.PageMeta -> PageMetaLayerC;
  AddressTranslatorLayerC.TLB -> TranslationLookasideBufferC;
  
  StreamStorageLayerC.TranslatedStorage -> AddressTranslatorLayerC;
  
  StorageInitC.PageAllocatorInit -> PageAllocatorLayerC;
  StorageInitC.MetaInit -> PageMetaLayerC;
  StorageInitC.AddressTranslatorInit -> AddressTranslatorLayerC;
  StorageInitC.PageMeta -> PageMetaLayerC;
  StorageInitC.TLB -> TranslationLookasideBufferC;
}