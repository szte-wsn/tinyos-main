#include "InputParser.hpp"

InputParser::InputParser(Config& config_in): config(config_in){
}


std::vector<Measurement> InputParser::getMeasurements(std::string& str){
	std::vector<Measurement> measures;
	std::string delm1 = ";";
	size_t pos = 0;
	size_t prev_pos = pos;
	while( (pos = str.find(delm1,prev_pos)) != std::string::npos){
		std::string tempMeasureStr = str.substr(prev_pos,pos-prev_pos);
		measures.push_back(InputParser::getMeasurement(tempMeasureStr));
		if(pos < str.length()-2){
			prev_pos = pos+1;
		}else{
			break;
		}
	}
	return measures;
}

Measurement InputParser::getMeasurement(std::string& str){
	Measurement temp;
	std::string delm2 = " ";
	std::string delm3 = ":";
	std::string delm4 = "/";
	size_t pos = 0;
	size_t prev_pos = pos;
	if((pos = str.find(delm2,prev_pos)) != std::string::npos){
		short tx1Id = stoi(str.substr(prev_pos,pos-prev_pos));
		if(config.isStable(tx1Id)){
			temp.setTx1(config.getStable(tx1Id));
		}
		if(config.isMobile(tx1Id)){
			temp.setTx1(config.getMobile(tx1Id));
		}
		prev_pos = pos + 1;
	}
	if((pos = str.find(delm2,prev_pos)) != std::string::npos){
		short tx2Id = stoi(str.substr(prev_pos,pos-prev_pos));
		if(config.isStable(tx2Id)){
			temp.setTx2(config.getStable(tx2Id));
		}
		if(config.isMobile(tx2Id)){
			temp.setTx2(config.getMobile(tx2Id));
		}
		prev_pos = pos + 1;
	}
	while( (pos = str.find(delm2,prev_pos)) != std::string::npos){
		short ID;
		short phase;
		short period;
		std::string tempMeasureStr = str.substr(prev_pos,pos-prev_pos);
		size_t pos_colon = tempMeasureStr.find(delm3,0);
		const std::string tempIdString = tempMeasureStr.substr(0,pos_colon);
		ID = stoi(tempIdString);
		const std::string tempPhasePeriodString = tempMeasureStr.substr(pos_colon+1,pos-prev_pos-pos_colon-1);
		size_t pos_slash = tempPhasePeriodString.find(delm4,0);
		const std::string tempPeriodString = tempPhasePeriodString.substr(0,pos_slash);
		const std::string tempPhaseString = tempPhasePeriodString.substr(pos_slash+1,tempPhasePeriodString.length()-pos_slash-1);
		phase = stoi(tempPhaseString);
		period = stoi(tempPeriodString);
		if(config.isStable(ID)){
			temp.addMoteMeasure(config.getStable(ID),phase, period);
		}
		if(config.isMobile(ID)){
			temp.addMoteMeasure(config.getMobile(ID),phase, period);
		}
		if(pos < str.length()-2){
			prev_pos = pos+1;
		}else{
			break;
		}
	}
	return temp;
}