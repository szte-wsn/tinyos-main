#include "Measurement.hpp"


Measurement::Measurement(Mote& tx1_in, Mote& tx2_in, std::map<Mote,short> phases_in, std::map<Mote,short> periods_in): tx1(tx1_in), tx2(tx2_in), phases(phases_in), periods(periods_in){
	
}

Measurement::Measurement(): tx1(-1,0,0),tx2(-1,0,0){
	phases = std::map<Mote,short>();
	periods = std::map<Mote,short>();
}

void Measurement::setTx1(Mote& tx1_in){ Measurement::tx1 = tx1_in; }
Mote Measurement::getTx1(){ return Measurement::tx1; }
void Measurement::setTx2(Mote& tx2_in){ Measurement::tx2 = tx2_in; }
Mote Measurement::getTx2(){ return Measurement::tx2; }

void Measurement::addMoteMeasure(Mote& mote_in, short phase_in, short period_in){
	 Measurement::phases.insert(std::pair<Mote,short>(mote_in,phase_in));
	 Measurement::periods.insert(std::pair<Mote,short>(mote_in,period_in));
}


std::ostream& operator<<(std::ostream& os, Measurement& measure){
	os << "TX1: " << std::setw(2) << measure.tx1 << std::endl;
	os << "TX2: " << std::setw(2) << measure.tx2 << std::endl;
	for (std::map<Mote,short>::reverse_iterator it=measure.phases.rbegin(); it!=measure.phases.rend(); ++it){
		os << std::setw(2) << (it->first).getID() << ": " << std::setw(4) << measure.phases[(it->first)] << std::setw(4) << measure.periods[ (it->first) ] << std::endl; 
	}
	return os;
}