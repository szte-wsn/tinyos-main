#include "PhaseMap2D.hpp"
#include <iostream>

#define TWOpi 6.28318530718
#define c_light 299792458
#define f_carrier 2400000000
#define lambda_carrier 0.12491352416
#define TWOPi_per_lambda_carrier 50.3002805295


PhaseMap2D::PhaseMap2D( double A_x, double A_y, double B_x, double B_y, double C_x, double C_y, double start_x, double end_x, double start_y, double end_y, double step_in){
	PhaseMap2D::A.x = A_x;
	PhaseMap2D::A.y = A_y;
	PhaseMap2D::B.x = B_x;
	PhaseMap2D::B.y = B_y;
	PhaseMap2D::C.x = C_x;
	PhaseMap2D::C.y = C_y;
	startX = start_x;
	startY = end_y;
	step = step_in;
	PhaseMap2D::phaseMap = cv::Mat::zeros( (end_y-start_y)/step, (end_x-start_x)/step, CV_64F );
	PhaseMap2D::generateMap(PhaseMap2D::phaseMap);
}

cv::Mat* PhaseMap2D::getPhaseMap(){
	return &(PhaseMap2D::phaseMap); 
}

void PhaseMap2D::display(){
	cv::Mat display(PhaseMap2D::phaseMap.size(),CV_8UC1);
	PhaseMap2D::phaseMap.convertTo(display, CV_8UC1, 255.0 / TWOpi, 0);
	applyColorMap(display, display, cv::COLORMAP_SUMMER);
	cv::imshow("Phase Map",display);
	cv::waitKey(0);
	//std::cout << phaseMap;
}

void PhaseMap2D::generateMap(cv::Mat& map){
	double dAC = sqrt( pow((PhaseMap2D::A.x-PhaseMap2D::C.x),2)+pow((PhaseMap2D::A.y-PhaseMap2D::C.y),2)); 
	double dBC = sqrt( pow((PhaseMap2D::B.x-PhaseMap2D::C.x),2)+pow((PhaseMap2D::B.y-PhaseMap2D::C.y),2));
	double dBC_minus_dAC = dBC - dAC;
	for(int i=0;i<map.size().height-1;i++){
		for(int j=0;j<map.size().width-1;j++){
			double x = PhaseMap2D::startX + j*PhaseMap2D::step;
			double y = PhaseMap2D::startY - i*PhaseMap2D::step;
			double dAD = sqrt( pow((PhaseMap2D::A.x-x),2)+pow((PhaseMap2D::A.y-y),2)); 
			double dBD = sqrt( pow((PhaseMap2D::B.x-x),2)+pow((PhaseMap2D::B.y-y),2));
			double temp = fmod((TWOPi_per_lambda_carrier * (dAD - dBD + dBC_minus_dAC)),TWOpi);
			if(temp < 0){
				temp = TWOpi + temp;
			}
			map.at<double>(i,j) = temp;
		}
	}
}






