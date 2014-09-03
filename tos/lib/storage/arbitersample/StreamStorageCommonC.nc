configuration StreamStorageCommonC{
	provides interface SplitControl;
}
implementation{
	components StreamStorageArbC;
	SplitControl = StreamStorageArbC;
}