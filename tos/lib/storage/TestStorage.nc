interface TestStorage{
	command void eraseTest(uint32_t pageNum);
	event void eraseDone(error_t err);
	command void writeTest(uint32_t pageNum);
	event void writeDone(error_t err);
	command void readTest(uint32_t pageNum);
	event void readDone(error_t err, uint16_t bufferError);
	
	command uint16_t getPageSize();
	command uint32_t getNumPages();
	command uint32_t getRandomPage();
}