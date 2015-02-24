
#include "Localization2D.hpp"
#include "Position.hpp"
#include "Mote.hpp"
#include <iostream>
#include <cmath>
#include "Config.hpp"
#include <string>
#include "Measurement.hpp"
#include "InputParser.hpp"
#include "PhaseCalculator.hpp"
#include <vector>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/contrib/contrib.hpp>

using namespace cv;

int main(int argc, char* argv[])
{
	int refID;
	if(argc != 2){
		std::cerr << "Usage: ./test referenceID < *.log \n";
		return 1;
	}else{
		refID = atoi(argv[1]);
		std::cout << "Ref ID: " << refID << std::endl;
	}

	#include "proba.conf"

	std::cout<< config << std::endl;
	InputParser input(config);

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
		for( std::vector<Measurement>::iterator it=measures.begin() ; it < measures.end(); it++){
			//std::cout << *it << std::endl;
			short refPhase = it->getPhases()[Mote(refID,0.0,0.0)];
			short refPeriod = it->getPeriods()[Mote(refID,0.0,0.0)];
			//std::cout << refPhase << " r, " << refPeriod <<"\n";
			for ( int i=1 ;i < 9 ;i++){
				if( it->getPhases().count(Mote(i,0.0,0.0)) != 0 ){
					if( i != refID){
						unsigned short otherPhase = it->getPhases()[ Mote(i,0.0,0.0) ];
						unsigned short otherPeriod = it->getPeriods()[ Mote(i,0.0,0.0) ];
						std::cout << PhaseCalculator::relPhase(refPhase,refPeriod,otherPhase,otherPeriod) << " ";
					}
				}
			}
			std::cout << "\n";
		}
	}
	cv::waitKey(0);
	return 0;

    return 0;
}
