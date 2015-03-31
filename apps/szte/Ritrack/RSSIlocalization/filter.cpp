#include "RSSIFilter.hpp"
#include <iostream>
#include <cmath>
#include <string>
#include "Measurement.hpp"
#include "InputParser.hpp"
#include <vector>

int main(int argc, char** argv){
	int numberOfData, selectedMote;
	if(argc != 3){
		std::cerr << "Usage: ./filter selectedMote NumberOfData" << std::endl;
		return -1;
	}else{
		numberOfData = std::stoi(std::string(argv[2]));
		selectedMote = std::stoi(std::string(argv[1]));
	}
	
	InputParser input;
	RSSIFilter rssifilter((short)numberOfData,(short)selectedMote,true);
	char in_array[150];
	while(!std::cin.eof()){
		std::cin.getline(in_array,150);
		std::string in(in_array);
		if(in == "q"){
			break;
		}else if(in == ""){
			continue;
		}
		Measurement measure = input.getMeasurement(in);
		rssifilter.processMeasure(measure);
	}
	return 0;


}
