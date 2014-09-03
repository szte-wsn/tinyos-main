generic configuration TranslationLookasideBufferC(uint8_t size){
  provides interface TranslationLookasideBuffer as TLB;
}
implementation{
  components new TranslationLookasideBufferP(size), MainC;
  TranslationLookasideBufferP.Init <- MainC.SoftwareInit;
  TLB = TranslationLookasideBufferP;
  
  components NoDiagMsgC as DiagMsgC;
  TranslationLookasideBufferP.DiagMsg -> DiagMsgC;
}