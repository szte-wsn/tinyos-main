generic configuration PageAllocatorLayerC(){
  uses interface PageLayer;
  provides interface PageAllocator;
  provides interface Set<uint32_t> as PageAllocatorInit;
}
implementation{
  components new PageAllocatorLayerP();
  PageLayer = PageAllocatorLayerP;
  PageAllocator = PageAllocatorLayerP;
  PageAllocatorInit = PageAllocatorLayerP;
  
  components NoDiagMsgC as DiagMsgC;
  PageAllocatorLayerP.DiagMsg -> DiagMsgC;
}