#include <stdio.h>
#include <stdlib.h>

void printDebug(char mode, int numberOfNodes, int currentNode){
	int i;
	if( mode == 'd' ){
		for(i=0;i<numberOfNodes-3;i++){
			if( i+3 == currentNode )
				printf(",  DEB, DSYN");
			else
				printf(", NDEB, RSYN");
		}
		if( currentNode == numberOfNodes )
			printf(",  DEB");
		else
			printf(", NDEB");
	}
}

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
	
	printf("#define  NUMBER_OF_INFRAST_NODES %d\n", numberOfNodes);
	if( mode == 'd' )
		printf("#define  NUMBER_OF_SLOTS %d\n", numberOfNodes+2*(numberOfNodes-2)-1);
	else
		printf("#define  NUMBER_OF_SLOTS %d\n", numberOfNodes);
	printf("#define  NUMBER_OF_RX 1\n");
	
	printf("const_uint8_t motesettings[NUMBER_OF_INFRAST_NODES][NUMBER_OF_SLOTS] = {\n");
	printf("\t//   0");
	for(i=1;i<numberOfNodes;i++){
		printf("%6d",i);
	}
	if( mode == 'd' ){
		for(i=0;i< (numberOfNodes-2)*2-1 ;i++){
			printf("%6d",i+numberOfNodes);
		}
	}
	printf("\n");
	
	
	printf("\t{ RSYN,  TX1,  W10");
	for(i=0;i<numberOfNodes-3;i++){
		printf(", RSYN");
	}
	printDebug(mode, numberOfNodes, 1);
	printf("},\n");
	printf("\t{ RSYN,  TX2,  W10");
	for(i=0;i<numberOfNodes-3;i++){
		printf(", RSYN");
	}	
	printDebug(mode, numberOfNodes, 2);
	printf("},\n");
	printf("\t{ SSYN,   RX,  W10");
	for(i=0;i<numberOfNodes-3;i++){
		printf(", RSYN");
	}
	printDebug(mode, numberOfNodes, 3);
	printf("},\n");
	for(j=0;j<numberOfNodes-3;j++){
		printf("\t{ RSYN,   RX,  W10");
		for(i=0;i<numberOfNodes-3;i++){
			if(i==j){
				printf(", SSYN");			
			}else{
				printf(", RSYN");
			}
		}
		printDebug(mode, numberOfNodes, j+4);
		if(j<numberOfNodes-4){
			printf("},\n");
		}else{
			printf("}\n");
		}
	}
	printf("};\n");
	return 0;
}
