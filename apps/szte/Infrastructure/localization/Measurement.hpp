#ifndef MEASUREMENT_HPP
#define MEASUREMENT_HPP

#include "Mote.hpp"
#include <string>
#include <map>
#include <iostream>
#include <iomanip>

class Measurement{

private:
	Mote tx1,tx2;  
	std::map<Mote,short> phases;
	std::map<Mote,short> periods;


public:
	Measurement(Mote& tx1_in, Mote& tx2_in, std::map<Mote,short> phases_in, std::map<Mote,short> periods_in);
	Measurement();

	void setTx1(Mote& tx1_in);
	Mote getTx1();
	void setTx2(Mote& tx2_in);
	Mote getTx2();
	
	std::map<Mote,short> getPhases();
	std::map<Mote,short> getPeriods();

	void addMoteMeasure(Mote& mote_in, short phase_in, short period_in);

	friend std::ostream& operator<<(std::ostream& os, Measurement& measure);
	friend class Localization2D;

};


#endif
