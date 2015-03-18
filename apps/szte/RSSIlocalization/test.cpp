
#include <iostream>
#include "PhaseMap2D.hpp"
#include "Localization2D.hpp"

using namespace cv;

int main(int argc, char* argv[])
{
    double distance = 0.1;
    double step = 0.005;
    double angleStep = 3;
    
    double xStart = -2.0;
    double xEnd = 4.0;
    double yStart = -3.0;
    double yEnd = 3.0;
    
    double x=atof(argv[1]);
    double y=atof(argv[2]);
    
    
    PhaseMap2D map(0,0,2,0,1,0,xStart,xEnd,yStart,yEnd,step);
    map.display();
	Localization2D local(distance, step, angleStep, map.getPhaseMap(), 20);
	
	double NW = map.getPhaseMap()->at<double>(abs(yStart-y)*(1/step)-(distance/step),abs(xStart-x)*(1/step)-(distance/step));
	double N  = map.getPhaseMap()->at<double>(abs(yStart-y)*(1/step)-(distance/step),abs(xStart-x)*(1/step));
	double NE = map.getPhaseMap()->at<double>(abs(yStart-y)*(1/step)-(distance/step),abs(xStart-x)*(1/step)+(distance/step));
	double W  = map.getPhaseMap()->at<double>(abs(yStart-y)*(1/step),abs(xStart-x)*(1/step)-(distance/step));
	double middle = map.getPhaseMap()->at<double>(abs(yStart-y)*(1/step),abs(xStart-x)*(1/step));
	double E  = map.getPhaseMap()->at<double>(abs(yStart-y)*(1/step),abs(xStart-x)*(1/step)+(distance/step));
	double SW = map.getPhaseMap()->at<double>(abs(yStart-y)*(1/step)+(distance/step),abs(xStart-x)*(1/step)-(distance/step));
	double S  = map.getPhaseMap()->at<double>(abs(yStart-y)*(1/step)+(distance/step),abs(xStart-x)*(1/step));
	double SE = map.getPhaseMap()->at<double>(abs(yStart-y)*(1/step)+(distance/step),abs(xStart-x)*(1/step)+(distance/step));
	
	/*cv::imshow("Locations",local.calculateLocations(	map.getPhaseMap()->at<double>(380,580),	
								map.getPhaseMap()->at<double>(380,600),	
								map.getPhaseMap()->at<double>(380,620),	
								map.getPhaseMap()->at<double>(400,580),	
								map.getPhaseMap()->at<double>(400,600),	
								map.getPhaseMap()->at<double>(400,620),	
								map.getPhaseMap()->at<double>(420,580),	
								map.getPhaseMap()->at<double>(420,600),	
								map.getPhaseMap()->at<double>(420,620)));
							
	cv::waitKey(0);*/
	
	/*cv::imshow("Locations",local.calculateLocations(	map.getPhaseMap()->at<double>(100,100),	
								map.getPhaseMap()->at<double>(100,120),	
								map.getPhaseMap()->at<double>(100,140),	
								map.getPhaseMap()->at<double>(120,100),	
								map.getPhaseMap()->at<double>(120,120),	
								map.getPhaseMap()->at<double>(120,140),	
								map.getPhaseMap()->at<double>(140,100),	
								map.getPhaseMap()->at<double>(140,120),	
								map.getPhaseMap()->at<double>(140,140)));
	cv::waitKey(0);*/
	
	cv::imshow("Locations",local.calculateLocations( NW, N, NE, W, middle, E, SW, S, SE ));
	cv::waitKey(0);
	
	
    return 0;
}
