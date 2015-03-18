#include "RSSIFilter.hpp"

RSSIFilter::RSSIFilter( short numberOfData_in, short selectedMote_in, bool median_in) : numberOfData(numberOfData_in), selectedMote(selectedMote_in), median(median_in) { 
	rssis = std::vector<std::vector<short>>();
	histogram = std::map<short,short>(); //used only if median is true
	//populate rssis  ->  SELECTED MOTE HAS THE HIGHEST NODEID
	for(int i=0;i<selectedMote-1;i++){
		rssis.push_back(std::vector<short>());
	}
	
}

void RSSIFilter::processMeasure(Measurement &measure){
	if(measure.rssi1.count(selectedMote) > 0){
		rssis[measure.tx1 - 1].push_back(measure.rssi1[selectedMote]);
		rssis[measure.tx2 - 1].push_back(measure.rssi2[selectedMote]);
		if(rssis[measure.tx1 - 1].size() >= numberOfData  || rssis[measure.tx2 - 1].size() >= numberOfData){
			processRssis();
		}
	}
}

void RSSIFilter::processRssis(){
	if(!median){
		std::string str = "";
		short avarages[selectedMote-1];
		for(int i=0; i<selectedMote-1 ;i++){
			int sum = 0;
			for(int j=0;j<rssis[i].size();j++){
				sum += rssis[i][j];
			}
			if(rssis[i].size() != 0){
				avarages[i] = sum / rssis[i].size();
			}else{
				avarages[i] = 0;
			}
			if(i==0){
				str += std::to_string(avarages[i]);
			}else{
				str += ", ";
				str += std::to_string(avarages[i]);
			}
			rssis[i].clear();
		}
		std::cout << str << std::endl;
	}else{
	
	}

}
