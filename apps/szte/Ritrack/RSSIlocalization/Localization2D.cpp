
#include "Localization2D.hpp"

#include <iostream>


Localization2D::Localization2D(double step_in, double angleStep_in, Config& config_in, double xStart_in, double yStart_in, double xEnd_in, double yEnd_in): config(config_in){
	Localization2D::step = step_in;
	Localization2D::angleStep = angleStep_in;
	Localization2D::xStart = xStart_in;
	Localization2D::xEnd = xEnd_in;
	Localization2D::yStart = yStart_in;
	Localization2D::yEnd = yEnd_in;
	//Localization2D::phaseMap = NULL;
	//Localization2D::calculatePositionOffsets();
}


void Localization2D::calculatePositionOffsets(){
//	for(std::vector<Mote>::iterator it=config.getMobiles().begin() ; it < config.getMobiles().end(); it++) {
//		mobileAngles.insert(std::pair<Mote,double>(*it,angle(Position<double>(0.0,0.0),(*it).getPosition())));
//		offsets.insert(std::pair<Mote,std::vector<Position<short>>>(*it,std::vector<Position<short>>()));
//	}
//	for(double angle=0.0;angle<360.0;angle+=Localization2D::angleStep){
//		double angleRad = angle*DEGINRAD;
//		for(std::vector<Mote>::iterator it=config.getMobiles().begin() ; it < config.getMobiles().end(); it++) {
//			double realAngle = angleRad + mobileAngles[*it];
//			short x = round(distance(Position<double>(0.0,0.0),(*it).getPosition())*cos(realAngle)/step);
//			short y = round(distance(Position<double>(0.0,0.0),(*it).getPosition())*sin(realAngle)/step);
//			offsets[*it].push_back(Position<short>(x,y));
//		}
//	}
}



cv::Mat Localization2D::calculateLocations(std::vector<Measurement> measures){
	Localization2D::locationMap = cv::Mat::zeros(round(1+(yStart-yEnd)/step),round(1+(xEnd-xStart)/step), CV_64F);
	//for all measures:
	for(std::vector<Measurement>::iterator measureit=measures.begin() ; measureit < measures.end(); measureit++) {
		std::cout << *measureit << std::endl;
		//for all pixels
		int i=0;
		int j=0;
		for(double y=yStart ; y>yEnd ; y-=step){
			j=0;
			for(double x=xStart ; x<xEnd ; x+=step){
				double correlationMax = -1.0;
				//for all angles
				for(double ang=0.0 ; ang< 360.0; ang+=angleStep){
					double correlation = 0.0;
					//for all pairs
					for(std::vector<std::pair<Mote,Mote>>::iterator pairit=config.getPairs().begin() ; pairit < config.getPairs().end(); pairit++) {
						if( measureit->phases.count(pairit->first.getID())==0 || measureit->phases.count(pairit->second.getID())==0){
							continue;
						}
						
						Mote Tx1(-1,0.0,0.0);
						Mote Tx2(-1,0.0,0.0);
						//Mote Rx1;
						//Mote Rx2;
						
						if( config.isMobile(measureit->tx1) ){
							Tx1 = config.getMobile(measureit->tx1);
						}else{
							Tx1 = config.getStable(measureit->tx1);
						}
						if( config.isMobile(measureit->tx2) ){
							Tx2 = config.getMobile(measureit->tx2);
						}else{
							Tx2 = config.getStable(measureit->tx2);
						}
						
						Position<double> moteFirstPos(0.0,0.0);
						if( config.isMobile(pairit->first.getID()) ){
							moteFirstPos = Position<double>(x,y).rotatedPosition( pairit->first.getPosition() + Position<double>(x,y), ang*DEGINRAD );
							//Rx1 = config.getMobile(pairit->first.getID());
						}else{
							moteFirstPos = pairit->first.getPosition();
							//Rx1 = config.getStable(pairit->first.getID());
						}
						Position<double> moteSecondPos(0.0,0.0); 
						if( config.isMobile(pairit->second.getID()) ){
							moteSecondPos = Position<double>(x,y).rotatedPosition( pairit->second.getPosition() + Position<double>(x,y), ang*DEGINRAD );
							//Rx2 = config.getMobile(pairit->second.getID());
						}else{
							moteSecondPos = pairit->second.getPosition();
							//Rx2 = config.getStable(pairit->second.getID());
						}
						double absPhaseFirstTx1 = PhaseCalculator::absPhase(Tx1.getPosition(),moteFirstPos);
						double absPhaseFirstTx2 = PhaseCalculator::absPhase(Tx2.getPosition(),moteFirstPos);
						double absPhaseSecondTx1 = PhaseCalculator::absPhase(Tx1.getPosition(),moteSecondPos);
						double absPhaseSecondTx2 = PhaseCalculator::absPhase(Tx2.getPosition(),moteSecondPos);
						double absPhaseFirst = PhaseCalculator::phaseDiff(absPhaseFirstTx1,absPhaseFirstTx2);
						double absPhaseSecond = PhaseCalculator::phaseDiff(absPhaseSecondTx1,absPhaseSecondTx2);
						double calculatedRelPhase = PhaseCalculator::phaseDiff(absPhaseFirst,absPhaseSecond);
						double measuredRelPhase = PhaseCalculator::relPhase(		measureit->phases[pairit->first.getID()],
						                                                		measureit->periods[pairit->first.getID()],
						                                                		measureit->phases[pairit->second.getID()],
						                                                		measureit->periods[pairit->second.getID()] );
						correlation += PhaseCalculator::phaseCorrelation(calculatedRelPhase,measuredRelPhase);
						//std::cout << x << " , " << y << std::endl;
						//std::cout << moteFirstPos << " , " << moteSecondPos << std::endl;
						//std::cout << pairit->first << " , " << pairit->second << std::endl;
						
					}
					if(correlation > correlationMax){
						correlationMax = correlation;
					}
				}
				locationMap.at<double>(i,j) += correlationMax;
				j++;
			}
			i++;
		}
	}
	return Localization2D::locationMap;
}
