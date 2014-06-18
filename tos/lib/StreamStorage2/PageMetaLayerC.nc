generic configuration PageMetaLayerC(){
  provides interface PageMeta;
  uses interface PageBuffer;
  provides interface Set<uint32_t> as MetaInit;
}
implementation{
  components new PageMetaLayerP();
  PageMeta = PageMetaLayerP;
  PageBuffer = PageMetaLayerP;
  MetaInit = PageMetaLayerP;

  components NoDiagMsgC as DiagMsgC;
  PageMetaLayerP.DiagMsg -> DiagMsgC;
}