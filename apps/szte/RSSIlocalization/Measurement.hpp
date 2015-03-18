#ifndef MEASUREMENT_HPP
#define MEASUREMENT_HPP

#include <string>
#include <map>
#include <iostream>
#include <iomanip>

class Measurement{

private:
	short tx1,tx2;  
	std::map<short,short> phases;
	std::map<short,short> periods;
	std::map<short,short> rssi1;
	std::map<short,short> rssi2;


public:
	Measurement(short& tx1_in, short& tx2_in, std::map<short,short> phases_in, std::map<short,short> periods_in, std::map<short,short> rssi1_in, std::map<short,short> rssi2_in);
	Measurement();

	void setTx1(short& tx1_in);
	short getTx1();
	void setTx2(short& tx2_in);
	short getTx2();
	

	void addMoteMeasure(short& mote_in, short phase_in, short period_in, short rssi1_in, short rssi2_in);

	friend std::ostream& operator<<(std::ostream& os, Measurement& measure);
	friend class Localization2D;
	friend class InputParser;
	friend class RSSIFilter;
	
};


#endif
