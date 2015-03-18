#include "PhaseMap2D.hpp"
#include <iostream>



PhaseMap2D::PhaseMap2D(Position<double> tl_in, Position<double> br_in, double& step_in): tl(tl_in), br(br_in){
	PhaseMap2D::step = step_in;
	PhaseMap2D::phaseMap = cv::Mat::zeros( (tl.getY()-br.getY())/step, (br.getX()-tl.getX())/step, CV_64F );
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
}

void PhaseMap2D::generateMap(const Mote& A, const Mote& B, const Mote& C){
	double dAC = distance(A.getPosition(),C.getPosition()); 
	double dBC = distance(B.getPosition(),C.getPosition());
	double dBC_minus_dAC = dBC - dAC;
	for(int i=0;i<PhaseMap2D::phaseMap.size().height-1;i++){
		double y = PhaseMap2D::tl.getY() - i*PhaseMap2D::step;
		for(int j=0;j<PhaseMap2D::phaseMap.size().width-1;j++){
			double x = PhaseMap2D::tl.getX() + j*PhaseMap2D::step;
			double dAD = distance(A.getPosition(),Position<double>(x,y)); 
			double dBD = distance(B.getPosition(),Position<double>(x,y)); 
			double temp = fmod((TWOPi_per_lambda_carrier * (dAD - dBD + dBC_minus_dAC)),TWOpi);
			if(temp < 0){
				temp = TWOpi + temp;
			}
			PhaseMap2D::phaseMap.at<double>(i,j) = temp;
		}
	}
}

void PhaseMap2D::generateMap(const Mote& A, const Mote& B){
	for(int i=0;i<PhaseMap2D::phaseMap.size().height-1;i++){
		double y = PhaseMap2D::tl.getY() - i*PhaseMap2D::step;
		for(int j=0;j<PhaseMap2D::phaseMap.size().width-1;j++){
			double x = PhaseMap2D::tl.getX() + j*PhaseMap2D::step;
			double dAD = distance(A.getPosition(),Position<double>(x,y)); 
			double dBD = distance(B.getPosition(),Position<double>(x,y)); 
			double temp = fmod((TWOPi_per_lambda_carrier * (dAD - dBD)),TWOpi);
			if(temp < 0){
				temp = TWOpi + temp;
			}
			PhaseMap2D::phaseMap.at<double>(i,j) = temp;
		}
	}
}






