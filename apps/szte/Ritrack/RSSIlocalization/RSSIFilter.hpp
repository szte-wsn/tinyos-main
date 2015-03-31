#ifndef RSSIFILTER_HPP
#define RSSIFILTER_HPP

#include "Measurement.hpp"
#include <iostream>
#include <vector>
#include <algorithm>

#define HIGH_RRSI 13
#define MAX_HIGHS 1

class RSSIFilter{

private:
	std::vector<std::vector<short>> rssis;	
	unsigned numberOfData;
	short selectedMote;
	bool median;
	std::map<short,short> histogram;
	std::vector<std::vector<short>> buffer;
	int superFrameCounter;
	
	short referenceTx1,referenceTx2;
	
	void addMeasure(std::vector<std::vector<short>> oneMeasure);
	void processRssis();

public:
	RSSIFilter( short numberOfData_in, short selectedMote_in, bool median_in);
	void processMeasure(Measurement &measure);

};

#endif
