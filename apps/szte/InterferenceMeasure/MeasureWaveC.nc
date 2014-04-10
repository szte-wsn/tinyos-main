module MeasureWaveC{
  provides interface MeasureWave;
  
  uses interface DiagMsg;
}
implementation{
  
  command uint16_t MeasureWave.getPeriod(uint8_t *data, uint16_t len, uint8_t *average){
    uint16_t i;
    uint32_t temp;
    uint16_t crossingCount = 0;
    uint16_t lastCrossing = 0;
    
    
    //first, calculate the average
    temp = 0;
    for(i=0;i<len;i++){
      temp += *(data+i);
    }
    *average = temp/len;
    
    if(call DiagMsg.record()){
      call DiagMsg.chr('A');
      call DiagMsg.uint16(*average);
      call DiagMsg.send();
    }
    
    i = 0;
    temp = 0;
    
    //we only search for RISING crossings
    
    while(  i<len && *(data+i) >= (*average - 1) )
      i++;
    
    if(call DiagMsg.record()){
      call DiagMsg.chr('F');
      call DiagMsg.uint16(i);
      call DiagMsg.send();
    }

    
    while( i<len ){
      //search the next crossing
      while( i<len && *(data+i) < *average )
        i++;
      
      if(call DiagMsg.record()){
        call DiagMsg.chr('X');
        call DiagMsg.uint16(i);
        call DiagMsg.uint16(lastCrossing);
        call DiagMsg.uint16(crossingCount);
        call DiagMsg.uint32(temp);
        call DiagMsg.send();
      }
      
      if( i<len ){ //new crossing point
        if( crossingCount!=0 ){
          temp += (i-lastCrossing);
        }
        crossingCount++;
        lastCrossing = i;
        while(  i<len && *(data+i) >= (*average - 1) ) //go through the upper half period, and a bit more, to avoid oscillation near the average
          i++;
      }
      
      if(call DiagMsg.record()){
        call DiagMsg.chr('Z');
        call DiagMsg.uint16(i);
        call DiagMsg.send();
      }
    }
    if( crossingCount > 1 )
      return temp/(crossingCount-1);
    else
      return 0;
  }
  
  command uint16_t MeasureWave.getPhase(uint8_t *data, uint16_t len, uint16_t period, uint8_t zeroPoint){
    return 0;
  }
}