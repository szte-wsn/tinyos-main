#ifndef INPUTPARSER_HPP
#define INPUTPARSER_HPP

#include "Config.hpp"
#include <vector>
#include "Measurement.hpp"


class InputParser{

public:
	InputParser(Config& config);
	std::vector<Measurement> getMeasurements(std::string& str);
	Measurement getMeasurement(std::string& str);


private:
	Config config;
	
};


#endif