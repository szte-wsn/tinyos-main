configuration StreamStorageRamC{
	provides interface StreamStorageErase;
	provides interface StreamStorageRead;
	provides interface StreamStorageWrite;
	provides interface SplitControl;
}
implementation{
	components StreamStorageRamP;
	StreamStorageErase = StreamStorageRamP;
	StreamStorageRead = StreamStorageRamP;
	StreamStorageWrite = StreamStorageRamP;
	SplitControl = StreamStorageRamP;
	
	components NoDiagMsgC as DiagMsgC;
	StreamStorageRamP.DiagMsg -> DiagMsgC;
}