#ifndef RSSIFILTER_HPP
#define RSSIFILTER_HPP

#include "Measurement.hpp"
#include <iostream>
#include <vector>

class RSSIFilter{

private:
	std::vector<std::vector<short>> rssis;	
	unsigned numberOfData;
	short selectedMote;
	bool median;
	std::map<short,short> histogram;
	
	void processRssis();

public:
	RSSIFilter( short numberOfData_in, short selectedMote_in, bool median_in);
	void processMeasure(Measurement &measure);

};

#endif
