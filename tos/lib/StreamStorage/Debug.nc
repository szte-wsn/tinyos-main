interface Debug{
	command uint8_t getStatus();
	command bool isResourceOwned();
	command void resetStatus();
	command void releaseResource();
}