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
		printf("{ DSYN, TX1, W100, RSYN, NDEB");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN, NDEB");
		}	
		printf("},\n");
		printf("{ RSYN, TX2, W100, RSYN, NDEB");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN, NDEB");
		}	
		printf("},\n");
		printf("{ RSYN,  RX, W100, SSYN,  DEB");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN, NDEB");
		}	
		printf("},\n");
		for(j=0;j<numberOfNodes-3;j++){
			printf("{ RSYN,  RX, W100, RSYN, NDEB");
			for(i=0;i<numberOfNodes-3;i++){
				if(i==j){
					printf(", SSYN,  DEB");			
				}else{
					printf(", RSYN, NDEB");
				}
			}	
			if(j<numberOfNodes-4){
				printf("},\n");
			}else{
				printf("}\n");
			}
		}
	}else{
		printf("{ DSYN, TX1, W100, RSYN");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN");
		}	
		printf("},\n");
		printf("{ RSYN, TX2, W100, RSYN");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN");
		}	
		printf("},\n");
		printf("{ RSYN,  RX, W100, SSYN");
		for(i=0;i<numberOfNodes-3;i++){
			printf(", RSYN");
		}	
		printf("},\n");
		for(j=0;j<numberOfNodes-3;j++){
			printf("{ RSYN,  RX, W100, RSYN");
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
