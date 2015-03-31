#ifndef LOCALIZATION2D_HPP
#define LOCALIZATION2D_HPP

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include "Position.hpp"
#include "Config.hpp"
#include "Measurement.hpp"
#include "Mote.hpp"
#include "PhaseCalculator.hpp"

#define PERIODMISMATCH -1.0
#define PERIODTOLERANCE 4
#define DEGINRAD 0.0174532925

class Localization2D{

public:
	Localization2D(double step_in, double angleStep_in, Config& config_in, double xStart_in, double yStart_in, double xEnd_in, double yEnd_in);
	cv::Mat calculateLocations(std::vector<Measurement> measures);

	
private:
	Config& config;
	double angleStep;
	double step;
	double xStart, xEnd, yStart, yEnd;
	cv::Mat locationMap;
	std::map<Mote,double> mobileAngles;
	std::map<Mote,std::vector<Position<double>>> offsets;
	void calculatePositionOffsets();

	
};
#endif
