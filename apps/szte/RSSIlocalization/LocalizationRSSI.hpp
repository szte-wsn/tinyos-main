#ifndef LOCALIZATION_HPP
#define LOCALIZATION_HPP

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include "Position.hpp"
#include "Config.hpp"
#include "Measurement.hpp"
#include "Mote.hpp"
#include "PhaseCalculator.hpp"
#include <set>

#define MAX_MEASURE_NUMBER 12
#define ERROR_RANGE 3

class LocalizationRSSI{

public:
	LocalizationRSSI(double step_in, Config& config_in, double xStart_in, double yStart_in, double xEnd_in, double yEnd_in);
	bool calculateLocations(std::vector<Measurement> measures, cv::Mat& localMap);

	
private:
	Config& config;
	double step;
	double xStart, xEnd, yStart, yEnd;
	cv::Mat locationMap;
	//helpers
	unsigned short measureCounter;
	std::set<Mote> appearedTx;
	std::map<Mote,std::map<Mote,double>> avarageRSSIs;
	
	void initavarageRSSIs();
	double getMinimalDistance(double rssi);
	double getMaximalDistance(double rssi);
	double getDistance(double rssi);
	
};
#endif
