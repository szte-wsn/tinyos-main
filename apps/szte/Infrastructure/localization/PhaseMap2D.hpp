#ifndef PHASEMAP2D_HPP
#define PHASEMAP2D_HPP

#include "Position.cpp"
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/contrib/contrib.hpp>

class PhaseMap2D{

public:
	PhaseMap2D( double A_x, double A_y, double B_x, double B_y, double C_x, double C_y, double start_x, double end_x, double start_y, double end_y, double step_in);
	void display();
	cv::Mat* getPhaseMap();

private:
	Position<double> A, B ,C;
	cv::Mat phaseMap;
	double step, startX, startY;
	
	void generateMap(cv::Mat& map);

};

#endif
