#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/ml/ml.hpp>

void readTrainDatas(std::ifstream& fs, cv::Mat& datas, cv::Mat& classes){
	std::string line;
	while (std::getline(fs, line)){
		std::vector<short> rssis;
		size_t pos_semicolon = line.find(";",0);
		short classID = (short)std::stoi(line.substr(0,pos_semicolon));
		size_t prev_pos = pos_semicolon+1;
		size_t pos = line.find(",",prev_pos);
		do{
			rssis.push_back((short)std::stoi(line.substr(prev_pos,pos-prev_pos)));
			prev_pos = pos + 1;
		}
		while( (pos = line.find(",",prev_pos)) != std::string::npos);
		rssis.push_back((short)std::stoi(line.substr(prev_pos,line.length()-prev_pos))); //last rssi value
		cv::Mat temp(1 , rssis.size() ,  CV_32FC1);
		for(int i=0;i<rssis.size();i++){
			temp.at<float>(0,i) = (float)rssis[i];
		}
		datas.push_back(temp.clone());
		cv::Mat classesTemp(1,1,CV_32FC1);
		classesTemp.at<float>(0,0) = (float)classID;
		classes.push_back(classesTemp.clone());
	}
}


int main(int argc, char** argv){
	
	int K;
	float posX,posY;
	char* filenameD;
	char* filenameP;
	std::map<short,std::pair<float,float>> coordinates;
	
	if(argc != 4){
		std::cerr << "Usage: ./localizer K(in K-NN) filenameToDatas filenameToCoordinates" << std::endl;
		return -1;
	}else{
		K = std::stoi(std::string(argv[1]));
		filenameD = argv[2];
		filenameP = argv[3];
	}
	
	std::ifstream fsD;
	std::ifstream fsP;
	
	fsD.open (filenameD, std::ifstream::in);
	fsP.open (filenameP, std::ifstream::in);
	
	if(!fsD.is_open()){
		std::cerr << "Error opening file: " << filenameD << std::endl;
		return -1;
	}
	if(!fsP.is_open()){
		std::cerr << "Error opening file: " << filenameP << std::endl;
		return -1;
	}
	
	//populate coordinates
	std::string line;
	while (std::getline(fsP, line)){ //line= classID;posX,posY
		size_t pos_colon = line.find(":",0);
		short classID = (short)std::stoi(line.substr(0,pos_colon));
		size_t pos_comma = line.find(",",0);
		float posX = std::stof(line.substr(pos_colon+1,pos_comma-pos_colon-1));
		float posY = std::stof(line.substr(pos_comma+1,line.length()-pos_comma-1));
		coordinates.insert(std::pair<short,std::pair<float,float>>(classID,std::pair<float,float>(posX,posY)));
	}
	
	cv::Mat datas;
	cv::Mat classes;
	readTrainDatas(fsD,datas,classes);
	
	CvKNearest knn(datas,classes);
	
	
	char in_array[100];
	std::cin.clear();
	while(1){
		std::cin.getline(in_array,100);
		std::string in(in_array);
		if(in == "q"){
			break;
		}else if(in == ""){
			continue;
		}
		std::cout << in << std::endl;
		std::vector<short> rssis;
		size_t prev_pos = 0;
		size_t pos = in.find(",",prev_pos);
		do{
			rssis.push_back((short)std::stoi(in.substr(prev_pos,pos-prev_pos)));
			prev_pos = pos + 1;
		}
		while( (pos = in.find(",",prev_pos)) != std::string::npos);
		rssis.push_back((short)std::stoi(in.substr(prev_pos,in.length()-prev_pos))); //last rssi value
		cv::Mat temp(1 , rssis.size() ,  CV_32FC1);
		for(int i=0;i<rssis.size();i++){
			temp.at<float>(0,i) = (float)rssis[i];
		}
		short result = (short)round(knn.find_nearest(temp , K));
		std::cout << "x: " << coordinates[result].first << " y: " << coordinates[result].second << std::endl;
	}
	fsD.close();
	fsP.close();
}
