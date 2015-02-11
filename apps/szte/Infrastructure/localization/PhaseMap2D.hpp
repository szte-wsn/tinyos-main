#ifndef PHASEMAP2D_HPP
#define PHASEMAP2D_HPP

#define c_light 299792458
#define f_carrier 2400000000
#define lambda_carrier 0.12491352416
#define TWOPi_per_lambda_carrier 50.3002805295
#define TWOpi 6.28318530718

#include "Position.hpp"
#include "Mote.hpp"
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/contrib/contrib.hpp>

class PhaseMap2D{

public:
	PhaseMap2D(Position<double> tl_in, Position<double> br_in, double& step_in);
	void display();
	cv::Mat* getPhaseMap();
	void generateMap(const Mote& A, const Mote& B, const Mote& C);
	void PhaseMap2D::generateMap(const Mote& A, const Mote& B);

private:
	cv::Mat phaseMap;
	double step;
	Position<double> tl, br;


};

void displayMat(cv::Mat& mat);
void tresholdMat(cv::Mat& mat, double tresh);

#endif
