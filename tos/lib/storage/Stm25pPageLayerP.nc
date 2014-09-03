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

#include "Stm25p.h"

module Stm25pPageLayerP {
  provides interface PageLayer[uint8_t id];
  uses interface Stm25pSector as Sector[ uint8_t id ];
  uses interface Resource as ClientResource[ uint8_t id ];
}

implementation{
  enum{
    S_IDLE,
    S_READ,
    S_WRITE,
    S_ERASE,
    S_REAL_ERASE,
  };
  enum{
    N=uniqueCount("Stm25p.Page"),
  };
  
  typedef struct client_data{
    uint8_t status;
    uint32_t pageNum;//page for read/write sector for erase
    uint8_t* buffer;
  } client_data;
  
  client_data clients[N];
  
  command error_t PageLayer.read[uint8_t id](uint32_t pageNum, void *buffer){
    if(pageNum >= (uint32_t)(call Sector.getNumSectors[id]() << (STM25P_SECTOR_SIZE_LOG2-STM25P_PAGE_SIZE_LOG2)))
      return EINVAL;
    if(clients[id].status==S_READ)
      return EALREADY;
    else if(clients[id].status!=S_IDLE)
      return EBUSY;
    
    clients[id].status=S_READ;
    clients[id].pageNum=pageNum;
    clients[id].buffer=buffer;
    return call ClientResource.request[id]();
  }
  command error_t PageLayer.write[uint8_t id](uint32_t pageNum, void *buffer){
    if(pageNum >= (uint32_t)(call Sector.getNumSectors[id]() << (STM25P_SECTOR_SIZE_LOG2-STM25P_PAGE_SIZE_LOG2)))
      return EINVAL;
    if(clients[id].status==S_WRITE)
      return EALREADY;
    else if(clients[id].status!=S_IDLE)
      return EBUSY;
    
    clients[id].status=S_WRITE;
    clients[id].pageNum=pageNum;
    clients[id].buffer=buffer;
    return call ClientResource.request[id]();
  }
  
  command error_t PageLayer.erase[uint8_t id](uint32_t sectorNum, bool realErase){
    if(sectorNum >= call Sector.getNumSectors[id]())
      return EINVAL;
    if(clients[id].status==S_ERASE)
      return EALREADY;
    else if(clients[id].status!=S_IDLE)
      return EBUSY;
    
    clients[id].status=S_ERASE;
    clients[id].pageNum=sectorNum;
    return call ClientResource.request[id]();
  }
  
  inline void signalDone(uint8_t id, uint8_t status, error_t error){
    clients[id].status=S_IDLE;
    call ClientResource.release[id]();
    switch(status){
      case S_READ:{
        signal PageLayer.readDone[id]( clients[id].pageNum, clients[id].buffer, error );
      }break;
      case S_WRITE:{
        signal PageLayer.writeDone[id]( clients[id].pageNum, clients[id].buffer, error );
      }break;
      case S_ERASE:{
        signal PageLayer.eraseDone[id]( clients[id].pageNum, TRUE, error );
      }break;
    }
  }
  
  event void ClientResource.granted[uint8_t id](){
    error_t lastError=SUCCESS;
    switch(clients[id].status){
      case S_READ:{
        lastError=call Sector.read[id]( clients[id].pageNum<<STM25P_PAGE_SIZE_LOG2, clients[id].buffer, STM25P_PAGE_SIZE );
      }break;
      case S_WRITE:{
        lastError=call Sector.write[id]( clients[id].pageNum<<STM25P_PAGE_SIZE_LOG2, clients[id].buffer, STM25P_PAGE_SIZE );
      }break;
      case S_ERASE:{
        lastError=call Sector.erase[id]( clients[id].pageNum, 1 );
      }break;
    }
    if(lastError != SUCCESS){
      signalDone(id, clients[id].status, lastError);
    }
  }
  
  event void Sector.writeDone[uint8_t id]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len, error_t error ){
      signalDone(id, S_WRITE, error);
  }
  
  event void Sector.eraseDone[uint8_t id]( uint8_t sector, uint8_t num_sectors, error_t error ){
      signalDone(id, S_ERASE, error);
  }
  
  event void Sector.readDone[uint8_t id]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len, error_t error ){
      signalDone(id, S_READ, error);
  }
  
  command uint16_t PageLayer.getPageSize[uint8_t id](){
    return STM25P_PAGE_SIZE;
  }
  
  command uint8_t PageLayer.getPageSizeLog2[uint8_t id](){
    return STM25P_PAGE_SIZE_LOG2;
  }
  
  command uint32_t PageLayer.getSectorSize[uint8_t id](){
    return STM25P_SECTOR_SIZE;
  }
  
  command uint8_t PageLayer.getSectorSizeLog2[uint8_t id](){
    return STM25P_SECTOR_SIZE_LOG2;
  }
  
  command uint32_t PageLayer.getNumPages[uint8_t id](){
    return (uint32_t)(call Sector.getNumSectors[id]())<<(STM25P_SECTOR_SIZE_LOG2-STM25P_PAGE_SIZE_LOG2);
  }
  
  command uint32_t PageLayer.getNumSectors[uint8_t id](){
    return call Sector.getNumSectors[id]();
  }
  
  event void Sector.computeCrcDone[uint8_t id]( stm25p_addr_t addr, stm25p_len_t len, uint16_t crc, error_t error ){}

  default command storage_addr_t Sector.getPhysicalAddress[ uint8_t id ]( storage_addr_t addr ) { return 0xffffffff; }
  default command uint8_t Sector.getNumSectors[ uint8_t id ]() { return 0; }
  default command error_t Sector.read[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len ) { return FAIL; }
  default command error_t Sector.write[ uint8_t id ]( stm25p_addr_t addr, uint8_t* buf, stm25p_len_t len ) { return FAIL; }
  default command error_t Sector.erase[ uint8_t id ]( uint8_t sector, uint8_t num_sectors ) { return FAIL; }
  default command error_t Sector.computeCrc[ uint8_t id ]( uint16_t crc, storage_addr_t addr, storage_len_t len ) { return FAIL; }
  
  default async command error_t ClientResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t ClientResource.release[ uint8_t id ]() { return FAIL; }
  
  default event void PageLayer.readDone[uint8_t id](uint32_t pageNum, void *buffer, error_t error){}
  default event void PageLayer.writeDone[uint8_t id](uint32_t pageNum, void *buffer, error_t error){}
  default event void PageLayer.eraseDone[uint8_t id](uint32_t sectorNum, bool realErase, error_t error){}
}