#include "InputParser.hpp"

InputParser::InputParser(){
}


Measurement InputParser::getMeasurement(std::string& str){

	//TX1, TX2,\tID,period,phase,rssi1,rssi2,\t......

	std::string comma = ",";
	size_t pos = 0;
	size_t prev_pos = pos;
	Measurement temp;
	//tx1 ID
	pos = str.find(comma,prev_pos);
	short tx1Id = stoi(str.substr(prev_pos,pos-prev_pos));
	temp.setTx1(tx1Id);
	prev_pos = pos + 1;
	//tx2 ID
	pos = str.find(comma,prev_pos);
	short tx2Id = stoi(str.substr(prev_pos,pos-prev_pos));
	temp.setTx2(tx2Id);
	prev_pos = pos + 1;
	//receivers
	while( (pos = str.find(comma,prev_pos)) != std::string::npos){
		short ID = stoi(str.substr(prev_pos,pos-prev_pos)); //due to \t
		prev_pos = pos + 1;
		pos = str.find(comma,prev_pos);
		short phase = stoi(str.substr(prev_pos,pos-prev_pos));
		prev_pos = pos + 1;
		pos = str.find(comma,prev_pos);
		short period = stoi(str.substr(prev_pos,pos-prev_pos));
		prev_pos = pos + 1;
		pos = str.find(comma,prev_pos);
		short rssi1 = stoi(str.substr(prev_pos,pos-prev_pos));
		prev_pos = pos + 1;
		pos = str.find(comma,prev_pos);
		short rssi2 = 0;
		if(pos == std::string::npos){
			rssi2 = stoi(str.substr(prev_pos,str.length()-prev_pos));
		}else{
			rssi2 = stoi(str.substr(prev_pos,pos-prev_pos));
			prev_pos = pos + 1;
		}
		temp.addMoteMeasure(ID,phase, period, rssi1, rssi2);
	}
	return temp;
}
