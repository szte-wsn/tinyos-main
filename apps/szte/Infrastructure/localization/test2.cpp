#include "Localization2D.hpp"
#include "Position.hpp"
#include "Mote.hpp"
#include <iostream>
#include <cmath>
#include "Config.hpp"
#include "PhaseMap2D.hpp"
#include <string>
#include "Measurement.hpp"
#include "InputParser.hpp"
#include <vector>

#define PI 3.14159265

int main(){

	Mote moteA(1,0,0);
	Mote moteB(2,2,0);
	Mote moteC(3,1,0);

	Mote mote4(4,-0.1,0.1);
	Mote mote5(5,0,0.1);
	Mote mote6(6,0.1,0.1);
	Mote mote7(7,-0.1,0);
	Mote mote8(8,0,0);
	Mote mote9(9,0.1,0);
	Mote mote10(10,-0.1,-0.1);
	Mote mote11(11,0,-0.1);
	Mote mote12(12,0.1,-0.1);

	double step = 0.01;
	double angle_step = 360.0;
	double deviation = 10.0;

	Config config;
	config.addStables( { moteA,moteB,moteC } );
	config.addMobiles( { mote4,mote5,mote6,mote7,mote8,mote9,mote10,mote11,mote12 } );

	std::cout<< config << std::endl;

	std::map<Mote,double> tempMap;
	tempMap.insert(std::pair<Mote,double>(moteA,1.55));

	PhaseMap2D map(Position<double>(-2,2),Position<double>(4,0),step);
	map.generateMap(moteA,moteB,moteC);
	map.display();
	double NW = map.getPhaseMap()->at<double>(90,290);
	double N  = map.getPhaseMap()->at<double>(90,300);
	double NE = map.getPhaseMap()->at<double>(90,310);
	double W  = map.getPhaseMap()->at<double>(100,290);
	double middle = map.getPhaseMap()->at<double>(100,300);
	double E  = map.getPhaseMap()->at<double>(100,300);
	double SW = map.getPhaseMap()->at<double>(110,290);
	double S  = map.getPhaseMap()->at<double>(110,300);
	double SE = map.getPhaseMap()->at<double>(110,310);

	Localization2D local(step,angle_step,deviation,config);

	InputParser input(config);
	//std::string in = "1 2 3:45/7 4:44/5 5:43/25 6:45/7 7:44/5 8:43/25 9:45/7 10:44/5 11:43/25 12:45/5 ;";
	std::string in = "1 2 3:43/17 5:45/0 6:42/10 7:43/11 8:43/36 9:42/25 10:42/40 11:13/5 12:42/8 ;1 2 3:41/2 4:41/28 5:44/30 6:42/2 7:42/39 9:42/10 10:42/27 11:13/10 12:42/35 ;1 2 3:43/33 4:42/18 5:40/25 6:42/41 7:43/30 8:42/12 10:42/18 11:17/8 12:42/27 ;";
	std::vector<Measurement> measures = input.getMeasurements(in);
	for(std::vector<Measurement>::iterator it=measures.begin() ; it < measures.end(); it++) {
		std::cout<<*it;
	}
	cv::Mat localMap = local.calculateLocations(measures,map,moteC);
	//std::cout << localMap << std::endl;
	displayMat(localMap);
	
	
	return 0;
}
