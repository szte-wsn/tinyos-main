generic configuration TestStorageC(uint8_t partition){
	provides interface TestStorage;
}
implementation{
	components TestStorageP, RandomC;
	components new Stm25pPageLayerC(partition) as PageLayerC; //TODO this should be platform independent
	TestStorage = TestStorageP;
	TestStorageP.Random -> RandomC;
	TestStorageP.PageLayer -> PageLayerC;
	
	#ifdef TESTSTORAGE_PRINT_BUFFER_ON_FAIL
	components DiagMsgC;
	TestStorageP.DiagMsg -> DiagMsgC;
	#endif
}