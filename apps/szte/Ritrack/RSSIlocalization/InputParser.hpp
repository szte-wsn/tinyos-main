#ifndef INPUTPARSER_HPP
#define INPUTPARSER_HPP

#include "Config.hpp"
#include <vector>
#include "Measurement.hpp"


class InputParser{

public:
	Measurement getMeasurement(std::string& str);
	InputParser();
};


#endif
