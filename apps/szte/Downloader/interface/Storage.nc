
interface Storage {
	
	/**
	  * Store measurements to a buffer.
	  * data - 8 bit array
	  * error SUCCESS the measure store is successful
	  * 	  FAIL    the buffer is full
	  */ 

	async command error_t store(uint8_t* data);
}
