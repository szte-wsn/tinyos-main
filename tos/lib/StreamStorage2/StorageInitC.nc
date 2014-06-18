generic configuration StorageInitC(){
  uses interface TranslationLookasideBuffer as TLB;
  uses interface PageMeta;
  provides interface SplitControl;
  
  uses interface Set<uint32_t> as PageAllocatorInit;
  uses interface Set<uint32_t> as MetaInit;
  uses interface AddressTranslatorInit;
}
implementation{
  components new StorageInitP();
  TLB = StorageInitP;
  PageMeta = StorageInitP;
  SplitControl = StorageInitP;
  
  PageAllocatorInit = StorageInitP.PageAllocatorInit;
  MetaInit = StorageInitP.MetaInit;
  AddressTranslatorInit = StorageInitP;
  
  components NoDiagMsgC as DiagMsgC;
  StorageInitP.DiagMsg -> DiagMsgC;
}