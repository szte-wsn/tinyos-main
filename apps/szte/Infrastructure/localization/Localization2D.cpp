
#include "Localization2D.hpp"

#include <iostream>


double distance(const Position<double>& a, const Position<double>& b){
	return sqrt( pow(a.getX()-b.getX(),2) + pow(a.getY()-b.getY(),2) );
}

double angle(const Position<double>& ref, const Position<double>& other){
	return atan2(other.getY()-ref.getY(),other.getX()-ref.getX());
}

double angleDiff(const double& phase1, const double& phase2){
	if( phase1==PERIODMISMATCH || phase2==PERIODMISMATCH){
		return 0.0;
	}
	return cos(phase1-phase2)+1.0;
}

double relPhase(const char& ref_phase,const char& ref_period,const char& other_phase,const char& other_period){
	if( abs(ref_period-other_period) > PERIODTOLERANCE){
		return PERIODMISMATCH;
	}else{
		double avg_period = (ref_period+other_period)/2.0;
		char phaseDiff = 0;
		if( (phaseDiff=ref_phase-other_phase)>=0 ){
				return (phaseDiff/avg_period)*TWOpi;
		}else{
				return ((avg_period+phaseDiff)/avg_period)*TWOpi;
		}
	}
}

Localization2D::Localization2D(double step_in, double angleStep_in, double deviation_in, Config& config_in): config(config_in){
	Localization2D::step = step_in;
	Localization2D::angleStep = angleStep_in;
	Localization2D::deviation = deviation_in * DEGINRAD;
	Localization2D::phaseMap = NULL;
	Localization2D::calculatePositionOffsets();
}


void Localization2D::calculatePositionOffsets(){
	for(std::vector<Mote>::iterator it=config.getMobiles().begin() ; it < config.getMobiles().end(); it++) {
		mobileAngles.insert(std::pair<Mote,double>(*it,angle(Position<double>(0.0,0.0),(*it).getPosition())));
		offsets.insert(std::pair<Mote,std::vector<Position<short>>>(*it,std::vector<Position<short>>()));
	}
	for(double angle=0.0;angle<360.0;angle+=Localization2D::angleStep){
		double angleRad = angle*DEGINRAD;
		for(std::vector<Mote>::iterator it=config.getMobiles().begin() ; it < config.getMobiles().end(); it++) {
			double realAngle = angleRad + mobileAngles[*it];
			short x = round(distance(Position<double>(0.0,0.0),(*it).getPosition())*cos(realAngle)/step);
			short y = round(distance(Position<double>(0.0,0.0),(*it).getPosition())*sin(realAngle)/step);
			offsets[*it].push_back(Position<short>(x,y));
		}
	}
}


cv::Mat Localization2D::calculateLocations(std::vector<Measurement> measures, PhaseMap2D& map, Mote& ref){
	Localization2D::locationMap = cv::Mat::zeros(map.getPhaseMap()->size() , CV_64F);
	//for all measures:
	for(std::vector<Measurement>::iterator it=measures.begin() ; it < measures.end(); it++) {
		//select mode: 3 stable mote / 2 stable mote + 1 known phase (now the first available)
		for (std::map<Mote,short>::reverse_iterator rit=(*it).phases.rbegin(); rit!=(*it).phases.rend(); ++rit){
			if(config.isStable( (rit->first).getID() )){
				//get the phasemap
				map.generateMap( (*it).getTx1(), (*it).getTx2(), (rit->first) );
				Localization2D::phaseMap = map.getPhaseMap();
				break;
			}
		}
		//get relative phases
		std::map<Mote,double> relPhases;
		for (std::map<Mote,short>::reverse_iterator rit=(*it).phases.rbegin(); rit!=(*it).phases.rend(); ++rit){
			if( (rit->first) != ref ){
				relPhases.insert(std::pair<Mote,double>((rit->first),relPhase( (*it).phases[ref],(*it).periods[ref],(*it).phases[ (rit->first) ],(*it).periods[ (rit->first) ] )));
				std::cout << rit->first << ": " << relPhases[(rit->first)] << std::endl;
			}
		}
		//for all pixels
		for(unsigned int i=0;i<phaseMap->size().height;i++){
			for(unsigned int j=0;j<phaseMap->size().width;j++){
				//std::cout << i << "," << j <<std::endl;
				double correlationMax = -1.0;
				//for all angles
				for(unsigned char ang=0; ang<floor(359/angleStep)+1;ang++){
					double correlation = 0.0;
					//for all mobile motes
					for(std::vector<Mote>::iterator moteit=config.getMobiles().begin() ; moteit < config.getMobiles().end(); moteit++) {
						unsigned int x=j+(offsets[(*moteit)])[ang].getX();
						unsigned int y=i+(offsets[(*moteit)])[ang].getY();
						if(x>=0 && x<phaseMap->size().width && y>=0 && y<phaseMap->size().height){
							correlation+=angleDiff(phaseMap->at<double>(y,x),relPhases[(*moteit)]);
						}
					}
					if(correlation > correlationMax){
						correlationMax = correlation;
					}
				}
				locationMap.at<double>(i,j) += correlationMax;
			}
		}
	}
	std::cout << "return jon!" << std::endl;
	return Localization2D::locationMap;
}
