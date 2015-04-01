#include "serial.hpp"
#include "packet.hpp"
#include "viterbi.hpp"
#include <vector>
#include <map>

#define HIGH_RRSI 13
#define MAX_HIGHS 1

class RSSIFilter : public Block {
public:
	struct Packet {
		std::vector<short> rssisOut;
	};

	Input<RipsDat::Packet> in;
	Output<Packet> out;
	
	RSSIFilter( short numberOfData_in, short selectedMote_in, bool median_in);
	void processMeasure(const RipsDat::Packet &pkt);	

private:


	void decode(const RipsDat::Packet &pkt);
	
	std::vector<std::vector<short>> rssis;	
	unsigned numberOfData;
	short selectedMote;
	bool median;
	std::map<short,short> histogram;
	std::vector<std::vector<short>> buffer;
	unsigned int superFrameCounter;
	
	unsigned short referenceTx1,referenceTx2;
	
	void addMeasure(std::vector<std::vector<short>> oneMeasure);
	void processRssis();

	
};

RSSIFilter::RSSIFilter(short numberOfData_in, short selectedMote_in, bool median_in)
	: in(bind(&RSSIFilter::decode, this)),
	numberOfData(numberOfData_in), selectedMote(selectedMote_in), median(median_in)
{
	rssis = std::vector<std::vector<short>>();
	buffer = std::vector<std::vector<short>>();
	histogram = std::map<short,short>(); //used only if median is true
	//populate rssis  ->  SELECTED MOTE HAS THE HIGHEST NODEID
	for(int i=0;i<selectedMote-1;i++){
		rssis.push_back(std::vector<short>());
	}
	
	for(int i=0;i<selectedMote-1;i++){
		buffer.push_back(std::vector<short>());
	}
	referenceTx1 = -1;
	referenceTx2 = -1;
	superFrameCounter = 0;
}

void RSSIFilter::decode(const RipsDat::Packet &pkt) {
	processMeasure(pkt);	
}

void RSSIFilter::addMeasure(std::vector<std::vector<short>> oneMeasure){
	//filtering
	short cnt = 0;
	short error = 0;
	for(std::vector<std::vector<short>>::iterator moteit=buffer.begin(); moteit!=buffer.end();moteit++){
		for(std::vector<short>::iterator rssiit=moteit->begin(); rssiit!=moteit->end();rssiit++){
			if( *rssiit >= HIGH_RRSI ){
				cnt++;
				break;
			}
		}
		//multiple mote has high RSSI
		if(cnt>MAX_HIGHS){
			error = 1;
			break;
		}	
	}
	if(error==1){
		//std::cerr << "Wi-Fi detected!" << std::endl;
		for(std::vector<std::vector<short>>::iterator moteit=buffer.begin(); moteit!=buffer.end();moteit++){
			moteit->clear();
		}
		return;
	}
	//add correct measures
	for(short i=0;i<selectedMote-1;i++){
		if(!buffer[i].empty()){
			rssis[i].insert(rssis[i].end(),buffer[i].begin(),buffer[i].end());
			buffer[i].clear();
		}
	}
	//std::cout << "Measures added!" << std::endl;
	if(superFrameCounter >= numberOfData){
		//std::cout << "Measures precessed!" << std::endl;
		superFrameCounter=0;
		processRssis();
	}
}

void RSSIFilter::processMeasure(const RipsDat::Packet &pkt){
	const RipsDat::Measurement *measure = pkt.get_measurement(selectedMote);
	if(measure != NULL){
		if(referenceTx1!=-1 && referenceTx2!=-1){
			if(referenceTx1==pkt.sender1  && referenceTx2==pkt.sender2 ){
				//supeerframe gone
				superFrameCounter++;
				addMeasure(buffer);
				buffer[pkt.sender1-1].push_back(measure->rssi1);
				buffer[pkt.sender2-1].push_back(measure->rssi2);
				//std::cout << "Superframe ended" << std::endl;
			}else{
				buffer[pkt.sender1-1].push_back(measure->rssi1);
				buffer[pkt.sender2-1].push_back(measure->rssi2);
			}
		}else{
			referenceTx1 = pkt.sender1;
			referenceTx2 = pkt.sender2;
			buffer[pkt.sender1-1].push_back(measure->rssi1);
			buffer[pkt.sender2-1].push_back(measure->rssi2);
			//std::cout << "References set: " << referenceTx1 << ", " << referenceTx2 << std::endl;
		}
	}
}

void RSSIFilter::processRssis(){
	if(!median){
		std::string str = "";
		short avarages[selectedMote-1];
		for(unsigned short i=0; i<selectedMote-1 ;i++){
			int sum = 0;
			for(unsigned short j=0;j<rssis[i].size();j++){
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
		std::string str = "";
		for(int i=0; i<selectedMote-1 ;i++){
			std::nth_element(rssis[i].begin(), rssis[i].begin()+rssis[i].size()/2, rssis[i].end());
			if(i!=0){
				str += ", ";
			}
			str += std::to_string( rssis[i][rssis[i].size()/2] );
			rssis[i].clear();
		}
		std::cout << str << std::endl;
	}
	
}

std::ostream& operator <<(std::ostream& stream, const RSSIFilter::Packet &packet) {
	return stream;
}

int main(int argc, char *argv[]) {
	Writer<RSSIFilter::Packet> writer;
	RipsDat ripsdat;
	RipsMsg ripsmsg;
	TosMsg tosmsg;
	RSSIFilter rssifilter(50,11,true);
	Reader<std::vector<unsigned char>> reader;

	connect(reader.out, tosmsg.sub_in);
	connect(tosmsg.out, ripsmsg.in);
	connect(ripsmsg.out, ripsdat.in);
	connect(ripsdat.out, rssifilter.in);
	connect(rssifilter.out, writer.in);

	reader.run();
	return 0;
}
