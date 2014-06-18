generic configuration StreamStorageLayerC(){
  provides interface StreamStorageErase;
  provides interface StreamStorageRead;
  provides interface StreamStorageWrite;
  uses interface TranslatedStorage;
}
implementation{
  components new StreamStorageLayerP();
  StreamStorageErase = StreamStorageLayerP;
  StreamStorageRead = StreamStorageLayerP;
  StreamStorageWrite = StreamStorageLayerP;
  TranslatedStorage = StreamStorageLayerP;
}