#ifndef LOCALIZATION_HPP
#define LOCALIZATION_HPP

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include "Position.hpp"
#include "Config.hpp"
#include "Measurement.hpp"
#include "Mote.hpp"
#include "PhaseMap2D.hpp"

#define PERIODMISMATCH -1.0
#define PERIODTOLERANCE 4
#define DEGINRAD 0.0174532925

class Localization2D{

public:
	Localization2D(double step_in, double angleStep_in, double deviation_in, Config& config_in);
	cv::Mat calculateLocations(std::vector<Measurement> measures, PhaseMap2D& map, Mote& ref);

	
private:
	Config& config;
	double deviation;
	double angleStep;
	double step;
	cv::Mat* phaseMap;
	cv::Mat locationMap;
	std::map<Mote,double> mobileAngles;
	std::map<Mote,std::vector<Position<short>>> offsets;
	void calculatePositionOffsets();

	
};
#endif
