#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv){
	int i=0,j,numberOfNodes;
	char mode;
	if(argc == 3){
		numberOfNodes = atoi(argv[1]);
		mode = (argv[2][0] == 'd')?'d':'n';
	}else{
		printf("Usage: ./schduleGenerator [numberOfMotes] [mode: d (debug) or n (no debug)]\n");
		return -1;
	}
	if(mode == 'd'){
		printf("{ SSYN, TX1, RSYN, NDEB");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN, NDEB");
		}	
		printf("},\n");
		printf("{ RSYN, TX2, RSYN, NDEB");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN, NDEB");
		}	
		printf("},\n");
		printf("{ RSYN,  RX, SSYN,  DEB");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN, NDEB");
		}	
		printf("},\n");
		for(j=0;j<numberOfNodes-3;j++){
			printf("{ RSYN,  RX, RSYN, NDEB");
			for(i=0;i<numberOfNodes-3;i++){
				if(i==j){
					printf(", SSYN,  DEB");			
				}else{
					printf(", RSYN, NDEB");
				}
			}	
			printf("},\n");	
		}
	}else{
		printf("{ SSYN, TX1, WCAL, RSYN");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN");
		}	
		printf("},\n");
		printf("{ RSYN, TX2, WCAL, RSYN");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN");
		}	
		printf("},\n");
		printf("{ RSYN,  RX, WCAL, SSYN");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN");
		}	
		printf("},\n");
		for(j=0;j<numberOfNodes-3;j++){
			printf("{ RSYN,  RX, WCAL, RSYN");
			for(i=0;i<numberOfNodes-3;i++){
				if(i==j){
					printf(", SSYN");			
				}else{
					printf(", RSYN");
				}
			}
			if(j<numberOfNodes-4){
				printf("},\n");
			}else{
				printf("}\n");
			}
		}
	}
	
	return 0;
}
