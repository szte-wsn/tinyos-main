generic configuration StorageFrameReadC(){
	provides interface FramedRead;
	uses interface StreamStorageRead;
}
implementation{
	components new StorageFrameReadP();
	FramedRead = StorageFrameReadP;
	StreamStorageRead = StorageFrameReadP;
	
	components DiagMsgC, new TimerMilliC();
}