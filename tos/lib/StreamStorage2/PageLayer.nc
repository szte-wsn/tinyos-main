/*
* Copyright (c) 2011, University of Szeged
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
/**
 * This interface is designed to create a low level uniformized api for 
 * storage chips. It's mainly designed for Atmel at45db, ST m25pXX, 
 * and SD/MMC cards.
 * 
 * It's based on two units: sectors (erase unit) and page (read/write
 * unit) You can read/write whole pages only, and erase whole sectors
 * only. Sectors are usually bigger than pages.
 * Before writing a page, it MUST be erased. Although it's not checked,
 * and some hardware is rewritable and does not require this, you should
 * do this for platform independent code. It shouldn't slow down your code
 * on rewritable hardware since it's immadeiatly returns SUCCESS.
 */
interface PageLayer {

  /**
   * Reads a whole page from the storage.
   */
  command error_t read(uint32_t pageNum, void *buffer);
  
  /**
   * Writes a whole page from the storage. The page should be erased.
   */
  command error_t write(uint32_t pageNum, void *buffer);
  
  /**
   * Erases a sector in the storage
   */
  command error_t erase(uint32_t sectorNum, bool realErase);
 
  /**
   * Signalled when reading succeeds or fails.
   */
  event void readDone(uint32_t pageNum, void *buffer, error_t error);
  
  /**
   * Signalled when writing succeeds or fails.
   */
  event void writeDone(uint32_t pageNum, void *buffer, error_t error);
  
  /**
   * Signalled when erasing succeeds or fails.
   */
  event void eraseDone(uint32_t sectorNum, bool realErase, error_t error);
  
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