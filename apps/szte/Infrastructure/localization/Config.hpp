#ifndef CONFIG_HPP
#define CONFIG_HPP

#include "Mote.hpp"
#include <vector>
#include <map>
#include <iostream>
#include <initializer_list>

class Config{

private:
	std::vector<Mote> stable; //absolute positions
	std::vector<Mote> mobile; //realtive positions
	
public:
	Config();
	Config(Config& config_in);
	std::vector<Mote>& getStables();
	Mote& getStable(const short& ID_in);
	bool isStable(const short& ID_in);
	std::map<short,Mote&> getStablesMap();
	
	
	std::vector<Mote>& getMobiles();
	Mote& getMobile(const short& ID_in);
	bool isMobile(const short& ID_in);
	Mote& getReferenceMobile();
	std::map<short,Mote&> getMobilesMap();
	
	template <class T>
	short addStables(std::initializer_list<T> list){
	    for( auto elem : list )
	    {
		addStable(elem);
	    }
	}
	bool addStable(Mote mote);
	bool addStable(const short& ID, const double& x, const double& y);
	
	template <class T>
	short addMobiles(std::initializer_list<T> list){
	    for( auto elem : list )
	    {
		addMobile(elem);
	    }
	}
	bool addMobile(Mote mote);
	bool addMobile(const short& ID, const double& x, const double& y);
	
	friend std::ostream& operator<<(std::ostream& os, Config& config);

};

#endif
