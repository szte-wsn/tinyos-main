generic configuration AddressTranslatorLayerC(bool circular){
  uses interface TranslationLookasideBuffer as TLB;
  uses interface PageMeta;
  provides interface TranslatedStorage;
  provides interface AddressTranslatorInit;
}
implementation{
  components new AddressTranslatorLayerP(circular);
  TLB = AddressTranslatorLayerP;
  PageMeta = AddressTranslatorLayerP;
  TranslatedStorage = AddressTranslatorLayerP;
  AddressTranslatorInit = AddressTranslatorLayerP;
  
  components NoDiagMsgC as DiagMsgC;
  AddressTranslatorLayerP.DiagMsg -> DiagMsgC;
}