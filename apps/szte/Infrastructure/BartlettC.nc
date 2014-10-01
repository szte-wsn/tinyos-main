module BartlettC{
	provides interface Filter<uint8_t>;
	uses interface DiagMsg;
}
implementation{
	command bool Filter.needSeparateBuffer(){
		return FALSE;
	}
	
	command void Filter.filter(uint8_t *input, uint8_t *output, uint16_t len, uint8_t windowlen){
		uint16_t i;
		uint8_t j;
		for(j=0;j<2;j++){
			uint8_t tempvalue = 0;
			uint8_t halfwindow = (windowlen>>1)+1;
			for(i=0;i<halfwindow;i++){
				tempvalue += input[i];
				output[i] = tempvalue;
			}
			for(i=halfwindow; i<len; i++){
				tempvalue += input[i];
				tempvalue -= input[i-halfwindow];
				output[i] = tempvalue;
			}
		}
	}
	//multiply method - way slower than the average method, but since it's ready, I keep it here
// 		for(i=0;i<len-windowlen;i++){
// 			uint8_t j;
// 			output[i]=input[i];
// 			for(j=0;j<windowlen;j++){
// 				if( j <= (windowlen>>1) ){
// 					output[i]+=input[i+j]*(j+1);
// 				} else {
// 					output[i]+=input[i+j]*(windowlen-j);
// 				}
// 			}
// 		}
// 		for(i=len-windowlen;i<len;i++){
// 			uint8_t j;
// 			output[i]=input[i];
// 			for(j=0;i+j<len;j++){
// 				if( j <= (windowlen>>1) ){
// 					output[i]+=input[i+j]*(j+1);
// 				} else {
// 					output[i]+=input[i+j]*(windowlen-j);
// 				}
// 			}
// 		}
}