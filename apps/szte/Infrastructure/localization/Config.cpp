#include "Config.hpp"
#include <iterator> 
#include <exception>

Config::Config(){
	Config::stable = std::vector<Mote>();
	Config::mobile = std::vector<Mote>();
}

Config::Config(Config& config_in){
	for(std::vector<Mote>::iterator it=config_in.stable.begin() ; it < config_in.stable.end(); it++) {
		Config::stable.push_back(*it);
	}
	for(std::vector<Mote>::iterator it=config_in.mobile.begin() ; it < config_in.mobile.end(); it++) {
		Config::mobile.push_back(*it);
	}
}


std::vector<Mote>& Config::getStables(){
	return Config::stable;
}

Mote& Config::getStable(const short& ID_in){
	for(std::vector<Mote>::iterator it=Config::stable.begin() ; it < Config::stable.end(); it++) {
		if((*it).getID() == ID_in) {
			return *it;
		}
	}
	throw;
	return Config::stable[0];
}

bool Config::isStable(const short& ID_in){
	for(std::vector<Mote>::iterator it=Config::stable.begin() ; it < Config::stable.end(); it++) {
		if((*it).getID() == ID_in) {
			return true;
		}
	}
	return false;
}

std::map<short,Mote&> Config::getStablesMap(){
	std::map<short,Mote&> moteMap;
	for(std::vector<Mote>::iterator it=Config::stable.begin() ; it < Config::stable.end(); it++) {
		moteMap.insert(std::pair<short,Mote&>((*it).getID(),*it));
	}	
	return moteMap;
}
		
std::vector<Mote>& Config::getMobiles(){
	return Config::mobile;
}

Mote& Config::getMobile(const short& ID_in){
	for(std::vector<Mote>::iterator it=Config::mobile.begin() ; it < Config::mobile.end(); it++) {
		if((*it).getID() == ID_in) {
			return *it;
		}
	}
	throw;
	return Config::mobile[0];
}

bool Config::isMobile(const short& ID_in){
	for(std::vector<Mote>::iterator it=Config::mobile.begin() ; it < Config::mobile.end(); it++) {
		if((*it).getID() == ID_in) {
			return true;
		}
	}
	return false;
}

Mote& Config::getReferenceMobile(){
	for(std::vector<Mote>::iterator it=Config::mobile.begin() ; it < Config::mobile.end(); it++) {
		if((*it).getPosition().getX()==0.0 && (*it).getPosition().getY()==0.0) {
			return *it;
		}
	}
	throw;
	return Config::mobile[0];
}

std::map<short,Mote&> Config::getMobilesMap(){
	std::map<short,Mote&> moteMap;
	for(std::vector<Mote>::iterator it=Config::mobile.begin() ; it < Config::mobile.end(); it++) {
		moteMap.insert(std::pair<short,Mote&>((*it).getID(),*it));
	}	
	return moteMap;
}

bool Config::addStable(Mote mote){
	Config::stable.push_back(mote);
}

bool Config::addStable(const short& ID, const double& x, const double& y){
	Config::stable.push_back(Mote(ID,x,y));
}

bool Config::addMobile(Mote mote){
	Config::mobile.push_back(mote);
}

bool Config::addMobile(const short& ID, const double& x, const double& y){
	Config::mobile.push_back(Mote(ID,x,y));
}

std::ostream& operator<<(std::ostream& os, Config& config){
	os << "Stables:" << std::endl;
	for(std::vector<Mote>::iterator it=config.stable.begin() ; it < config.stable.end(); it++) {
		os << *it << std::endl;
	}
	os << "Mobiles:" << std::endl;
	for(std::vector<Mote>::iterator it=config.mobile.begin() ; it < config.mobile.end(); it++) {
		os << *it << std::endl;
	}
	return os;
}

