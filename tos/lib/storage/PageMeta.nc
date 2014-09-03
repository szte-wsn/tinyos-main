/*
* Copyright (c) 2012, Unicomp Ltd.
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Andras Biro
*/ 
//TODO docs
interface PageMeta {
	
	command uint32_t getLastAddress();

	/**
	* Reads a whole page from the storage, to a buffer, or get a buffer from the cashed ones
	*/
	command error_t readPage(uint32_t pageNum);
	
	/**
	* Signalled when reading succeeds or fails.
	*/
	event void readPageDone(uint32_t pageNum, void *buffer, uint32_t startAddress, uint16_t filledBytes, error_t error);
	
	/**
	* Reads a whole page from the storage, to a buffer, or get a buffer from the cashed ones
	*/
	command error_t readMeta(uint32_t pageNum);
	
	/**
	* Signalled when reading succeeds or fails.
	*/
	event void readMetaDone(uint32_t pageNum, void *buffer, error_t error);
	
	/**
	* Releases the read buffer
	*/
	command void releaseReadBuffer();
	
	/**
	* Returns the address of the write buffer, and locks it
	*/
	command void* getWriteBuffer();
	
	/**
	* Flushes the write buffer to the flash. The buffer must be locked with getWriteBuffer
	*/
	command error_t flushWriteBuffer(uint16_t filledBytes);
	
	/**
	* Signaled when writing the buffer succeeds
	*/
	event void flushWriteBufferDone(uint32_t pageNum, uint32_t startAddress, uint16_t filledBytes, uint32_t lostBytes, error_t error);
	
	/**
	* Releases the write buffer
	*/
	command void releaseWriteBuffer();
	
	/**
	* Erases the storage
	*/
	command error_t eraseAll(bool realErase);
	
	/**
	* Signalled when erasing succeeds or fails.
	*/
	event void eraseDone(bool realErase, error_t error);
	
	/**
	 * Invalidates puffers in memory from @fromPage to @toPage (including both)
	 */
	command void invalidate(uint32_t fromPage, uint32_t toPage);
	
	/**
	* Returns the size of a page in bytes
	*/
	command uint16_t getPageSize();
	
	/**
	* Returns the size of a sector in bytes
	*/
	command uint32_t getSectorSize();
	
	/**
	* Returns the number of pages in the current volume
	*/
	command uint32_t getNumPages();
	
	/**
	* Returns the number of sectors in the current volume
	*/
	command uint32_t getNumSectors();
}