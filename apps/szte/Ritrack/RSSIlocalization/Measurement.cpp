#include "Measurement.hpp"


Measurement::Measurement(short& tx1_in, short& tx2_in, std::map<short,short> phases_in, std::map<short,short> periods_in, std::map<short,short> rssi1_in, std::map<short,short> rssi2_in): tx1(tx1_in), tx2(tx2_in), phases(phases_in), periods(periods_in), rssi1(rssi1_in), rssi2(rssi2_in){
	
}

Measurement::Measurement(): tx1(-1),tx2(-1){
	phases = std::map<short,short>();
	periods = std::map<short,short>();
	rssi1 = std::map<short,short>();
	rssi2 = std::map<short,short>();
}

void Measurement::setTx1(short& tx1_in){ Measurement::tx1 = tx1_in; }
short Measurement::getTx1(){ return Measurement::tx1; }
void Measurement::setTx2(short& tx2_in){ Measurement::tx2 = tx2_in; }
short Measurement::getTx2(){ return Measurement::tx2; }

void Measurement::addMoteMeasure(short& mote_in, short phase_in, short period_in, short rssi1_in, short rssi2_in){
	 Measurement::phases.insert(std::pair<short,short>(mote_in,phase_in));
	 Measurement::periods.insert(std::pair<short,short>(mote_in,period_in));
	 Measurement::rssi1.insert(std::pair<short,short>(mote_in,rssi1_in));
	 Measurement::rssi2.insert(std::pair<short,short>(mote_in,rssi2_in));
}


std::ostream& operator<<(std::ostream& os, Measurement& measure){
	os << std::setw(2) << measure.tx1;
	os << std::setw(2) << ", " << measure.tx2;
	for (std::map<short,short>::reverse_iterator it=measure.phases.rbegin(); it!=measure.phases.rend(); ++it){
		os << ",\t" << std::setw(2) << (it->first) << ", " << std::setw(2) << measure.periods[(it->first)] << std::setw(2) << ", " << measure.phases[ (it->first) ] << ", " << measure.rssi1[(it->first)] << ", " << measure.rssi2[(it->first)]; 
	}
	return os;
}
