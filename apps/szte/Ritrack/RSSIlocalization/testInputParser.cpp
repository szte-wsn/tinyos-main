#include <iostream>
#include <cmath>
#include <string>
#include "Measurement.hpp"
#include "InputParser.hpp"
#include <vector>


#define PI 3.14159265

int main(){

	InputParser input;
	char in_array[150];
	while(1){
		std::cin.getline(in_array,150);
		std::string in(in_array);
		if(in == "q"){
			break;
		}else if(in == ""){
			continue;
		}
		Measurement measure = input.getMeasurement(in);
		std::cout << measure << std::endl;
	}
	return 0;
}
