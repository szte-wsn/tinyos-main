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

interface PageAllocator {

  /**
   * Reads a whole page from the storage.
   */
  command error_t read(uint32_t pageNum, void *buffer);
  
  /**
   * Writes a whole page from the storage.
   */
  command error_t writeNext(void *buffer);
  
  /**
   * Erases the storage
   */
  command error_t eraseAll(bool realErase);
 
  /**
   * Signalled when reading succeeds or fails.
   */
  event void readDone(uint32_t pageNum, void *buffer, error_t error);
  
  /**
   * Signalled when writing succeeds or fails.
   */
  event void writeNextDone(uint32_t pageNum, void *buffer, uint32_t lostSectors, error_t error);
  
  /**
   * Signalled when erasing succeeds or fails.
   */
  event void eraseDone(bool realErase, error_t error);
  
  /**
   * Returns the size of a page in bytes
   */
  command uint16_t getPageSize();
  
  /**
   * Returns the 2 base logarithm of pagesize
   */
  command uint8_t getPageSizeLog2();
  
  /**
   * Returns the size of a sector in bytes
   */
  command uint32_t getSectorSize();
  
  /**
   * Returns the 2 base logarithm of sectorsize
   */
  command uint8_t getSectorSizeLog2();
  
  /**
   * Returns the number of pages in the current volume
   */
  command uint32_t getNumPages();
  
  /**
   * Returns the number of sectors in the current volume
   */
  command uint32_t getNumSectors();
}