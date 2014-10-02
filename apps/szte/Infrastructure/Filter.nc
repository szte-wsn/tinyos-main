interface Filter<val_t>{
	command bool needSeparateBuffer();
	command void filter(val_t *inData, val_t *outData, uint16_t len, uint8_t windowlen);
}