interface StreamDownloaderInfo{
	command uint16_t getNodeId();
	command uint32_t convertTimeStamp(uint32_t other, bool localToRemote);
	command uint32_t convertTimeStampToRelativeTime(uint32_t timestamp);
	command uint32_t getOffset();
	command uint32_t getSkew();
}