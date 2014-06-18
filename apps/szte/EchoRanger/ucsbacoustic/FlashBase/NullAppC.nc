configuration NullAppC{}
implementation {
	components MainC, NullC;
	NullC.Boot -> MainC;
	
	components StreamDownloaderC;
	NullC.SplitControl -> StreamDownloaderC;
	components StreamStorageCommonC;
	NullC.StorageControl -> StreamStorageCommonC;
	
	components new StorageFrameReadC();
	StorageFrameReadC.StreamStorageRead -> StreamDownloaderC;
	NullC.Resource -> StreamDownloaderC;
	NullC.DownloadDone -> StreamDownloaderC;
	NullC.FramedRead -> StorageFrameReadC;
	NullC.StreamDownloaderInfo -> StreamDownloaderC;
	
	components new TimerMilliC();
	NullC.Timer -> TimerMilliC;
	
	components DiagMsgC as DiagMsgC;
	NullC.DiagMsg -> DiagMsgC;
}

