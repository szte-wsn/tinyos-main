#include <fstream>
#include <iostream>
#include <string>
#include <vector>

int main(int argc, char** argv){
	
	int classID;
	float posX,posY;
	char* filenameD;
	char* filenameP;
	
	if(argc != 6){
		std::cerr << "Usage: ./fingerprinter ClassID posX posY filenameToDatas filenameToCoordinates" << std::endl;
		return -1;
	}else{
		classID = std::stoi(std::string(argv[1]));
		posX = std::stof(std::string(argv[2]));
		posY = std::stof(std::string(argv[3]));
		filenameD = argv[4];
		filenameP = argv[5];
	}
	
	std::ofstream fsD;
	std::ofstream fsP;
	
	fsD.open (filenameD, std::fstream::app);
	fsP.open (filenameP, std::fstream::app);
	
	if(!fsD.is_open()){
		std::cerr << "Error opening file: " << filenameD << std::endl;
		return -1;
	}
	if(!fsP.is_open()){
		std::cerr << "Error opening file: " << filenameP << std::endl;
		return -1;
	}
	
	fsP << classID << ":" << posX << "," << posY << std::endl;
	
	char in_array[100];
	while(!std::cin.eof()){
		std::cin.getline(in_array,100);
		std::string in(in_array);
		if(in == "q"){
			break;
		}else if(in == ""){
			continue;
		}
		fsD << classID << "; " << in << std::endl;
	}
	fsD.close();
	fsP.close();
}
