
#include "LocalizationRSSI.hpp"

#include <iostream>


LocalizationRSSI::LocalizationRSSI(double step_in, Config& config_in, double xStart_in, double yStart_in, double xEnd_in, double yEnd_in): config(config_in){
	LocalizationRSSI::step = step_in;
	LocalizationRSSI::xStart = xStart_in;
	LocalizationRSSI::xEnd = xEnd_in;
	LocalizationRSSI::yStart = yStart_in;
	LocalizationRSSI::yEnd = yEnd_in;
	LocalizationRSSI::measureCounter = 1;
	initavarageRSSIs();
}

void LocalizationRSSI::initavarageRSSIs(){
	for( std::vector<Mote>::iterator it=LocalizationRSSI::config.mobile.begin(); it!=LocalizationRSSI::config.mobile.end(); it++){
		LocalizationRSSI::avarageRSSIs.insert(std::pair<Mote,std::map<Mote,double>>(*it,std::map<Mote,double>()));
	}
}

double LocalizationRSSI::getMinimalDistance(double rssi){
	return getDistance(rssi+ERROR_RANGE);
}

double LocalizationRSSI::getMaximalDistance(double rssi){
	return getDistance(rssi-ERROR_RANGE);
}

double LocalizationRSSI::getDistance(double rssi){
	return 4.0/rssi;
}


bool LocalizationRSSI::calculateLocations(std::vector<Measurement> measures, cv::Mat& localMap){
	//Localization2D::locationMap = cv::Mat::zeros(round(1+(yStart-yEnd)/step),round(1+(xEnd-xStart)/step), CV_64F);
	for(std::vector<Measurement>::iterator measureit=measures.begin() ; measureit < measures.end(); measureit++) {
		if(measureCounter < MAX_MEASURE_NUMBER){
			measureCounter++;
			//std::cout << measureCounter << std::endl;
			if(appearedTx.count(measureit->getTx1()) == 0 ){
				appearedTx.insert(measureit->getTx1());
				for( std::map<Mote,std::map<Mote,double>>::iterator mobileit = avarageRSSIs.begin() ; mobileit != avarageRSSIs.end() ; mobileit++ )
				{
					mobileit->second.insert(std::pair<Mote,double>(measureit->getTx1(),(double)measureit->rssi1[mobileit->first]));
				}
			}else{
				//already added,just add the new rssi values
				for (std::map<Mote,short>::iterator receiverit=measureit->rssi1.begin(); receiverit!=measureit->rssi1.end(); ++receiverit)			
				{
					avarageRSSIs[receiverit->first][measureit->getTx1()] +=  measureit->rssi1[receiverit->first];
					avarageRSSIs[receiverit->first][measureit->getTx1()] /= 2;
				}
			}
			if(appearedTx.count(measureit->getTx2()) == 0 ){
				appearedTx.insert(measureit->getTx2());
				for( std::map<Mote,std::map<Mote,double>>::iterator mobileit = avarageRSSIs.begin() ; mobileit != avarageRSSIs.end() ; mobileit++ )
				{
					mobileit->second.insert(std::pair<Mote,double>(measureit->getTx2(),(double)measureit->rssi2[mobileit->first]));
				}
			}else{
				//already added,just add the new rssi values
				for (std::map<Mote,short>::iterator receiverit=measureit->rssi2.begin(); receiverit!=measureit->rssi2.end(); ++receiverit)			
				{
					avarageRSSIs[receiverit->first][measureit->getTx2()] +=  measureit->rssi2[receiverit->first];
					avarageRSSIs[receiverit->first][measureit->getTx2()] /= 2;
				}
			}
		}else{
			//process data
			for( std::map<Mote,std::map<Mote,double>>::iterator mobileit = avarageRSSIs.begin() ; mobileit != avarageRSSIs.end() ; mobileit++ )
			{
				std::cout << mobileit->first.getID() << " from: ";
				for( std::map<Mote,double>::iterator it = avarageRSSIs[mobileit->first].begin() ; it != avarageRSSIs[mobileit->first].end() ; it++ )
				{
					std::cout << "ID: " << it->first.getID() << " AvrRSSI: " << it->second << "\t";
					cv::Mat temp = cv::Mat::zeros(localMap.size().height,localMap.size().width, CV_64F);
					int motePosY = round( (yStart - it->first.getPosition().getY())/step);
					int motePosX = round((it->first.getPosition().getX() - xStart)/step);
					short bigRadius = round(getMaximalDistance( it->second)/step );
					short smallRadius = round(getMinimalDistance( it->second)/step );
					if(bigRadius<=0 || smallRadius<=0){
						continue;
					}
					cv::circle(temp,cv::Point(motePosX,motePosY),bigRadius,cv::Scalar(255,255,255,255),-1);
					cv::circle(temp,cv::Point(motePosX,motePosY),smallRadius,cv::Scalar(0,0,0,255),-1);
					localMap += temp;
				}
				std::cout << std::endl;
			}
			//reset containers
			measureCounter = 1;
			appearedTx = std::set<Mote>();
			avarageRSSIs = std::map<Mote,std::map<Mote,double>>();
			initavarageRSSIs();
			return true;
		}
	}
	return false;
}
