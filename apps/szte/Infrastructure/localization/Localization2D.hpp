#ifndef LOCALIZATION_HPP
#define LOCALIZATION_HPP

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include "Position.cpp"

class Localization2D{

public:
	Localization2D(double distance_in, double step_in, double angleStep_in, cv::Mat* phaseMap_in, double deviation_in);
	cv::Mat calculateLocations(double NW, double N, double NE, double W, double middle, double E, double SW, double S, double SE);

	
private:
	double deviation;
	std::vector<Position<short> > smallCirclePositions;
	std::vector<Position<short> > bigCirclePositions;
	double angleStep;
	double step;
	double distance; //between two nodes in the grid
	cv::Mat* phaseMap;
	cv::Mat locationMap;
	
	void calculatePositionOffsets(std::vector<Position<short> >& small, std::vector<Position<short> >& big);

	
};
#endif
