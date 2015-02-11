#include "Localization2D.hpp"
#include "Position.hpp"
#include "Mote.hpp"
#include <iostream>
#include <cmath>
#include "Config.hpp"
#include <string>
#include "Measurement.hpp"
#include "InputParser.hpp"
#include <vector>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/contrib/contrib.hpp>

#include <chrono>

#define PI 3.14159265

void displayMat(cv::Mat& mat){
	cv::Mat display(mat.size(),CV_8UC1);
	double min, max;
	cv::minMaxLoc(mat, &min, &max);
	mat.convertTo(display, CV_8UC1, 255.0 / max, 0);
	applyColorMap(display, display, cv::COLORMAP_SUMMER);
	cv::imshow("Display",display);
	cv::waitKey(500);
}

void tresholdMat(cv::Mat& mat, double tresh){
	for(int i=0;i<mat.size().height;i++){
		for(int j=0;j<mat.size().width;j++){
			if(mat.at<double>(i,j)>tresh){
				mat.at<double>(i,j)=1.0;
			}else{
				mat.at<double>(i,j)=0.0;
			}
		}
	}
}


int main(){

	double step = 0.01;
	double angle_step = 360.0;

	#include "../cpp/4tx4anchor/first.conf"

	std::cout<< config << std::endl;

	//PhaseMap2D map(Position<double>(-2,2),Position<double>(4,0),step);
	//map.generateMap(moteA,moteB,moteC);

	Localization2D local(step,angle_step,config,0.0,4.0,4.8,0.8);

	InputParser input(config);
	//std::string in;
	char in_array[50000];
	while(1){
		std::cin.getline(in_array,50000);
		std::string in(in_array);
		if(in == "q"){
			break;
		}else if(in == ""){
			continue;
		}
		std::vector<Measurement> measures = input.getMeasurements(in);
		std::chrono::high_resolution_clock::time_point t1 = std::chrono::high_resolution_clock::now();
		cv::Mat localMap = local.calculateLocations(measures);
		std::chrono::high_resolution_clock::time_point t2 = std::chrono::high_resolution_clock::now();
		auto duration = std::chrono::duration_cast<std::chrono::seconds>( t2 - t1 ).count();
		std::cout << "Duration: " << duration << std::endl;
		//tresholdMat(localMap,13.0);
		displayMat(localMap);
	}
	cv::waitKey(0);
	return 0;
}
