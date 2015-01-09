
#include "Localization2D.hpp"

#include <iostream>

#define DEGINRAD 0.0174532925

Localization2D::Localization2D(double distance_in, double step_in, double angleStep_in, cv::Mat* phaseMap_in, double deviation_in){
	Localization2D::distance = distance_in;
	Localization2D::step = step_in;
	Localization2D::angleStep = angleStep_in;
	Localization2D::deviation = deviation_in * DEGINRAD;
	Localization2D::phaseMap = phaseMap_in;
	Localization2D::locationMap = cv::Mat::zeros(Localization2D::phaseMap->size() , CV_8UC1);
	Localization2D::calculatePositionOffsets(Localization2D::smallCirclePositions, Localization2D::bigCirclePositions);
}


void Localization2D::calculatePositionOffsets(std::vector<Position<short> >& small, std::vector<Position<short> >& big){
	double r_small = Localization2D::distance / Localization2D::step;
	double r_big = (sqrt(2)*Localization2D::distance) / Localization2D::step;
	for(double angle=0;angle<=90;angle+=Localization2D::angleStep){
		double anglePlus45 = (angle>45)?(angle-45):(angle + 45);
		double angleRad = DEGINRAD * angle;
		double anglePlus45Rad = DEGINRAD * anglePlus45;
		double cos_angle = cos(angleRad);
		double sin_angle = sin(angleRad);
		double cos_anglePlus45 = cos(anglePlus45Rad);
		double sin_anglePlus45 = sin(anglePlus45Rad);
		Position<short> temp_small((short)round(r_small*cos_angle),(short)round(r_small*sin_angle));
		small.push_back(temp_small);
		Position<short> temp_big((short)round(r_big*cos_anglePlus45),(short)round(r_big*sin_anglePlus45));
		big.push_back(temp_big);
	}
}


cv::Mat Localization2D::calculateLocations(double NW, double N, double NE, double W, double middle, double E, double SW, double S, double SE){
	double deviation = Localization2D::deviation;
	for(int i=(sqrt(2)*Localization2D::distance)/Localization2D::step;i+1<Localization2D::phaseMap->size().width -((sqrt(2)*Localization2D::distance) / Localization2D::step);i++){
		for(int j=(sqrt(2)*Localization2D::distance)/Localization2D::step;j+1<Localization2D::phaseMap->size().height -((sqrt(2)*Localization2D::distance) / Localization2D::step);j++){
			double angle = 0;
			if( abs(Localization2D::phaseMap->at<double>(j,i) - middle) < deviation ){
				for(short k=0;k<Localization2D::smallCirclePositions.size();k++){
					angle+=Localization2D::angleStep;
					short sxOffset = Localization2D::smallCirclePositions[k].x;
					short syOffset = Localization2D::smallCirclePositions[k].y;
					short sxI = i + sxOffset;
					short syI = j - syOffset;
					short sxII = i - syOffset;
					short syII = j - sxOffset;
					short sxIII = i - sxOffset;
					short syIII = j + syOffset;
					short sxIV = i + syOffset;
					short syIV = j + sxOffset;
					short bxOffset = Localization2D::bigCirclePositions[k].x;
					short byOffset = Localization2D::bigCirclePositions[k].y;
					short bxI = i + bxOffset;
					short byI = j - byOffset;
					short bxII = i - byOffset;
					short byII = j - bxOffset;
					short bxIII = i - bxOffset;
					short byIII = j + byOffset;
					short bxIV = i + byOffset;
					short byIV = j + bxOffset;
					//4cases
					if(angle > 45){
						if( abs(Localization2D::phaseMap->at<double>(syI,sxI) - N) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syII,sxII) - W) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syIII,sxIII) - S) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(syIV,sxIV) - E) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byI,bxI) - NE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - NW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - SW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byIV,bxIV) - SE) < deviation){
							Localization2D::locationMap.at<unsigned char>(j,i) = 255;
							//std::cout<< 255 << " on position: " << j << " , " << i << std:: endl;
							break;
						}
						if( abs(Localization2D::phaseMap->at<double>(syI,sxI) - E) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syII,sxII) - N) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syIII,sxIII) - W) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(syIV,sxIV) - S) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byI,bxI) - SE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - NE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - NW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byIV,bxIV) - SW) < deviation){
							Localization2D::locationMap.at<unsigned char>(j,i) = 255;
							//std::cout<< 255 << " on position: " << j << " , " << i << std:: endl;
							break;
						}
						if( abs(Localization2D::phaseMap->at<double>(syI,sxI) - S) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syII,sxII) - E) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syIII,sxIII) - N) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(syIV,sxIV) - W) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byI,bxI) - SW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - SE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - NE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byIV,bxIV) - NW) < deviation){
							Localization2D::locationMap.at<unsigned char>(j,i) = 255;
							//std::cout<< 255 << " on position: " << j << " , " << i << std:: endl;
							break;
						}
						if( abs(Localization2D::phaseMap->at<double>(syI,sxI) - W) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syII,sxII) - S) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syIII,sxIII) - E) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(syIV,sxIV) - N) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byI,bxI) - NW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - SW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - SE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byIV,bxIV) - NE) < deviation){
							Localization2D::locationMap.at<unsigned char>(j,i) = 255;
							//std::cout<< 255 << " on position: " << j << " , " << i << std:: endl;
							break;
						}
					}else{
						if( abs(Localization2D::phaseMap->at<double>(syI,sxI) - N) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syII,sxII) - W) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syIII,sxIII) - S) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(syIV,sxIV) - E) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byI,bxI) - NW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - SW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - SE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byIV,bxIV) - NE) < deviation){
							Localization2D::locationMap.at<unsigned char>(j,i) = 255;
							//std::cout<< 255 << " on position: " << j << " , " << i << std:: endl;
							break;
						}
						if( abs(Localization2D::phaseMap->at<double>(syI,sxI) - E) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syII,sxII) - N) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syIII,sxIII) - W) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(syIV,sxIV) - S) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byI,bxI) - NE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - NW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - SW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byIV,bxIV) - SE) < deviation){
							Localization2D::locationMap.at<unsigned char>(j,i) = 255;
							//std::cout<< 255 << " on position: " << j << " , " << i << std:: endl;
							break;
						}
						if( abs(Localization2D::phaseMap->at<double>(syI,sxI) - S) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syII,sxII) - E) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syIII,sxIII) - N) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(syIV,sxIV) - W) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byI,bxI) - SE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - NE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - NW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byIV,bxIV) - SW) < deviation){
							Localization2D::locationMap.at<unsigned char>(j,i) = 255;
							//std::cout<< 255 << " on position: " << j << " , " << i << std:: endl;
							break;
						}
						if( abs(Localization2D::phaseMap->at<double>(syI,sxI) - W) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syII,sxII) - S) < deviation &&
					    	abs(Localization2D::phaseMap->at<double>(syIII,sxIII) - E) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(syIV,sxIV) - N) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byI,bxI) - SW) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - SE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byII,bxII) - NE) < deviation &&
				     	    	abs(Localization2D::phaseMap->at<double>(byIV,bxIV) - NW) < deviation){
							Localization2D::locationMap.at<unsigned char>(j,i) = 255;
							//std::cout<< 255 << " on position: " << j << " , " << i << std:: endl;
							break;
						}
					}
				}
			}
		}
	}
	return locationMap;
}
