#include "Localizer.hpp"

void displayMat(cv::Mat& mat){
	cv::Mat display(mat.size(),CV_8UC1);
	double min, max;
	cv::minMaxLoc(mat, &min, &max);
	mat.convertTo(display, CV_8UC1, 255.0 / max, 0);
	//applyColorMap(display, display, cv::COLORMAP_SUMMER);
	cv::imshow("Display",display);
	cv::waitKey(0);
}

void tresholdMat(cv::Mat& mat, double tresh){
	double min, max;
	cv::minMaxLoc(mat, &min, &max);
	for(int i=0;i<mat.size().height;i++){
		for(int j=0;j<mat.size().width;j++){
			if(mat.at<double>(i,j)>=(tresh*max)){
				mat.at<double>(i,j)=1.0;
			}else{
				mat.at<double>(i,j)=0.0;
			}
		}
	}
}


float RSSIdifference(int rssi1, int rssi2){
	if(rssi1 >= rssi2){
		if(rssi2 != 0){
			return 1.0*rssi1/rssi2;
		}else{
			return 5.0; //TODO: what to do if one of the RRSI is 0, no interference!
		}
	}else{
		if(rssi1 != 0){
			return 1.0*rssi2/rssi1;
		}else{
			return 5.0;
		}
	}
}

Localizer::Localizer(float step_in, float xStart_in, float yStart_in, float xEnd_in, float yEnd_in)
	: mobileMote(-1,0.0,0.0), in(bind(&Localizer::decode, this))
{
	Localizer::step = step_in;
	Localizer::xStart = xStart_in;
	Localizer::xEnd = xEnd_in;
	Localizer::yStart = yStart_in;
	Localizer::yEnd = yEnd_in;
	Localizer::locationMap = cv::Mat::zeros(round(1+(yStart-yEnd)/step),round(1+(xEnd-xStart)/step), CV_64F);
	Localizer::binaryMap = cv::Mat::zeros(round(1+(yStart-yEnd)/step),round(1+(xEnd-xStart)/step), CV_8UC1);
	Localizer::mask = cv::imread("mask.bmp",CV_LOAD_IMAGE_GRAYSCALE);
	cv::resize(mask,mask,locationMap.size());
	boxPairs.push_back(std::pair<uint,uint>(1,2));
	//boxPairs.push_back(std::pair<uint,uint>(2,3));
	//boxPairs.push_back(std::pair<uint,uint>(3,4));
	//boxPairs.push_back(std::pair<uint,uint>(1,4));
	//boxPairs.push_back(std::pair<uint,uint>(5,6));
	//boxPairs.push_back(std::pair<uint,uint>(6,7));
	//boxPairs.push_back(std::pair<uint,uint>(7,8));
	//boxPairs.push_back(std::pair<uint,uint>(5,8));
	//boxPairs.push_back(std::pair<uint,uint>(9,10));
	for(uint i=0;i<boxPairs.size();i++){
		maxRSSIs.push_back(0);
	}

	std::vector<Competition::TrainingData> data;
	
	Competition::read_training_data(data);
	
	for(uint i=0; i<data.size(); i++){
		for(uint j=0; j<data[i].fingerprints.size(); j++){
			cv::Mat temp(1 , data[i].fingerprints[j].size() ,  CV_32FC1);
			for(uint k=0; k<data[i].fingerprints[j].size(); k++){
				temp.at<float>(0,k) = data[i].fingerprints[j][k];
			}
			cv::Mat classesTemp(1,1,CV_32FC1);
			classesTemp.at<float>(0,0) = (float)data[i].id;
			datas.push_back(temp.clone());
			classes.push_back(classesTemp.clone());
		}
		coordinates.push_back(std::pair<int,std::pair<float,float>>(data[i].id,std::pair<float,float>(data[i].x,data[i].y)));
	}
	
	
	//set config
	std::vector<Competition::StaticNode> nodes;
	Competition::read_static_nodes(nodes);
	for(uint i=0;i<nodes.size();i++){
		stables.push_back(Mote((short)nodes[i].nodeid,nodes[i].x,nodes[i].y));
		config.addStable(stables[i]);
	}
	Localizer::mobileId = Competition::MOBILE_NODEID;
	mobileMote.setID(mobileId);
	config.addMobile(mobileMote);
	//need to set pairs
	for(uint i=0;i<boxPairs.size();i++){
		if(!config.pairExists(mobileId,(boxPairs[i].first)*3)){
			config.addPair(mobileMote,config.getStable( (boxPairs[i].first)*3 ));
		}
		if(!config.pairExists(mobileId,(boxPairs[i].second)*3)){
			config.addPair(mobileMote,config.getStable( (boxPairs[i].second)*3 ));
		}
	}
	std::cout << "END: Constructor" << std::endl;
}

void Localizer::decode(const FrameMerger::Frame &frame){
	std::set<short> selectedSlots =  getSelectedSlots(frame);
	std::cout << "END: Boxpair selection" << std::endl;
	getCorrelationMap(frame,selectedSlots);  //uses locationMap
	std::cout << "END: Get correlation map" << std::endl;
	//displayMat(locationMap);
	std::vector<Position<double>> maximums = getMaximumPositions(); //uses locationMap
	std::cout << "END: Get maximums" << std::endl;
	Position<double> maxPos = getMotePosition(maximums,frame,selectedSlots);
	std::cout << "END: Get position" << std::endl;
	out.send(maxPos);
}

std::set<short> Localizer::getSelectedSlots(const FrameMerger::Frame& frame){
	//std::cout << config << std::endl;
	std::set<short> selectedSlots;
	unsigned short selectedPair = 255;
	for(auto slotit = frame.slots.begin(); slotit!=frame.slots.end(); slotit++){
		if(slotit->get_data(mobileId) == NULL){
			continue;
		}
		for(uint i=0;i<boxPairs.size();i++){
			if( (boxPairs[i].first-1)*3 +1 == slotit->sender1 && (boxPairs[i].first-1)*3 + 2 == slotit->sender2){
				maxRSSIs[i] += slotit->get_data(mobileId)->rssi1;
				maxRSSIs[i] += slotit->get_data(mobileId)->rssi2;
			}
			if( (boxPairs[i].second-1)*3 +1 == slotit->sender1 && (boxPairs[i].second-1)*3 + 2 == slotit->sender2){
				maxRSSIs[i] += slotit->get_data(mobileId)->rssi1;
				maxRSSIs[i] += slotit->get_data(mobileId)->rssi2;
			}
		}
	}
	uint nearest = maxRSSIs[0];
	selectedPair = 0;
	for(uint i=1;i<boxPairs.size();i++){
		if(maxRSSIs[i] > nearest){
			nearest = maxRSSIs[i];
			selectedPair = i;
		}
	}
	
	float diff1 = -1.0;
	int slotId1 = -1;
	float diff2 = -1.0;
	int slotId2 = -1;
	for(auto slotit = frame.slots.begin(); slotit!=frame.slots.end(); slotit++){
		if(slotit->sender1 == (boxPairs[selectedPair].first-1)*3 +1 && slotit->sender2 == (boxPairs[selectedPair].first-1)*3 +2){
			if(diff1 == -1.0){
				diff1 = RSSIdifference(slotit->get_data(mobileId)->rssi1,slotit->get_data(mobileId)->rssi2);
				slotId1 = slotit->slot;
			}else{
				diff2 = RSSIdifference(slotit->get_data(mobileId)->rssi1,slotit->get_data(mobileId)->rssi2);
				slotId2 = slotit->slot;
				if(diff1 <= diff2){
					selectedSlots.insert(slotId1);
				}else{
					selectedSlots.insert(slotId2);
				}
				break;
			}
		}
	}
	diff1 = -1.0;
	slotId1 = -1;
	diff2 = -1.0;
	slotId2 = -1;
	for(auto slotit = frame.slots.begin(); slotit!=frame.slots.end(); slotit++){
		if(slotit->sender1 == (boxPairs[selectedPair].second-1)*3+1 && slotit->sender2 == (boxPairs[selectedPair].second-1)*3 + 2){
			if(diff1 == -1.0){
				diff1 = RSSIdifference(slotit->get_data(mobileId)->rssi1,slotit->get_data(mobileId)->rssi2);
				slotId1 = slotit->slot;
			}else{
				diff2 = RSSIdifference(slotit->get_data(mobileId)->rssi1,slotit->get_data(mobileId)->rssi2);
				slotId2 = slotit->slot;
				if(diff1 <= diff2){
					selectedSlots.insert(slotId1);
				}else{
					selectedSlots.insert(slotId2);
				}
				break;
			}
		}
	}
	//selected Slots:
	//for(auto it = selectedSlots.begin(); it != selectedSlots.end(); it++){
	//	std::cout << *it << std::endl;
	//}
	return selectedSlots;
}

cv::Mat* Localizer::getCorrelationMap(const FrameMerger::Frame& frame,std::set<short> selectedSlots){
	Localizer::locationMap.setTo(cv::Scalar(0.0));
	//std::cout << frame << std::endl;
	for(auto slotit = frame.slots.begin(); slotit!=frame.slots.end(); slotit++){
		if(slotit->get_data(mobileId) == NULL){
			continue;
		}
		if(selectedSlots.count(slotit->slot) == 0){
			continue;
		}
		double mobileMeasuredPhase = slotit->get_data(mobileId)->phase * TWOpi;
		float mobileConfidence = slotit->get_data(mobileId)->conf;
		if(mobileMeasuredPhase < 0.0){
			continue;
		}
		//get TX Motes
		Mote tx1 = config.getStable(slotit->sender1);
		Mote tx2 = config.getStable(slotit->sender2);

		//for all rec pairs
		for(std::vector<std::pair<Mote,Mote>>::iterator pairit=config.getPairs().begin() ; pairit < config.getPairs().end(); pairit++) {
			if(pairit->first.getID() != mobileId){
				continue;
			}
			Mote otherMote = pairit->second;
			if(slotit->get_data(otherMote.getID()) == NULL){
				continue;
			}
			double otherMeasuredPhase = slotit->get_data(otherMote.getID())->phase * TWOpi;
			float otherConfidence = slotit->get_data(otherMote.getID())->conf;
			if(otherMeasuredPhase < 0.0){
				continue;
			}
			double absPhaseOtherFromTx1 = PhaseCalculator::absPhase(tx1.getPosition(),otherMote.getPosition());
			double absPhaseOtherFromTx2 = PhaseCalculator::absPhase(tx2.getPosition(),otherMote.getPosition());
			double calcPhaseOther = PhaseCalculator::phaseDiff(absPhaseOtherFromTx1,absPhaseOtherFromTx2);
			
			double measuredRelPhase = PhaseCalculator::phaseDiff(mobileMeasuredPhase,otherMeasuredPhase);
			float confidence = mobileConfidence*otherConfidence;
			
			int i=0;
			int j=0;
			for(double y=yStart ; y>yEnd ; y-=step){
				j=0;
				for(double x=xStart ; x<xEnd ; x+=step){
					if(mask.at<uint8_t>(i,j) > 0){
						Position<double> mobilePos(x,y);
						double absPhaseMobileFromTx1 = PhaseCalculator::absPhase(tx1.getPosition(),mobilePos);
						double absPhaseMobileFromTx2 = PhaseCalculator::absPhase(tx2.getPosition(),mobilePos);
						double calcPhaseMobile = PhaseCalculator::phaseDiff(absPhaseMobileFromTx1,absPhaseMobileFromTx2);
						double calculatedRelPhase = PhaseCalculator::phaseDiff(calcPhaseOther,calcPhaseMobile);
						locationMap.at<double>(i,j) += PhaseCalculator::phaseCorrelation(calculatedRelPhase,measuredRelPhase)*confidence;
					}
					j++;
				}
				i++;
			}
		}
	}
	for(auto slotit = frame.slots.begin(); slotit!=frame.slots.end(); slotit++){
		if(slotit->get_data(mobileId) == NULL){
			continue;
		}
		if(selectedSlots.count(slotit->slot) == 0){
			continue;
		}
		Mote tx1 = config.getStable(slotit->sender1);
		int motePosY = 0;
		int motePosX = 0;
		float avarageRSSI = (slotit->get_data(mobileId)->rssi1 + slotit->get_data(mobileId)->rssi2) / 2.0;
		motePosY = round( (yStart - tx1.getPosition().getY())/step);
		motePosX = round((tx1.getPosition().getX() - xStart)/step);
		short radius = -1;
		if(avarageRSSI > 10.0){
			continue;
		}else if(avarageRSSI > 5.0){
			radius = 1/step;
		}else if(avarageRSSI > 0.0){
			radius = 2/step;
		}else{
			radius = 4/step;
		}
		cv::circle(locationMap,cv::Point(motePosX,motePosY),radius,cv::Scalar(0,0,0,255),-1);
	}
	return &locationMap;			
}


std::vector<Position<double>> Localizer::getMaximumPositions(){
	double min, max, thres=0.97;
	std::vector< Position<double> > maximums;
	cv::minMaxLoc(locationMap, &min, &max);
	for(int i=0;i<locationMap.size().height;i++){
		for(int j=0;j<locationMap.size().width;j++){
			if(locationMap.at<double>(i,j)>=(thres*max)){
				binaryMap.at<uint8_t>(i,j)=255;
			}else{
				binaryMap.at<uint8_t>(i,j)=0;
			}
		}
	}
	//displayMat(binaryMap);
	std::vector<std::vector<cv::Point> > contours;
	cv::findContours( binaryMap, contours, CV_RETR_LIST, CV_CHAIN_APPROX_TC89_L1 );
	//Get the moments
	std::vector<cv::Moments> mu(contours.size() );
	for( uint i = 0; i < contours.size(); i++ ){
		mu[i] = cv::moments( contours[i], false ); 
	}
	//Get the mass centers:
	std::vector<cv::Point2f> mc( contours.size() );
	for( uint i = 0; i < contours.size(); i++ ){
		 mc[i] = cv::Point2f( mu[i].m10/mu[i].m00 , mu[i].m01/mu[i].m00 );
		 if(mc[i].x != NAN && mc[i].y != NAN && mc[i].x>0 && mc[i].y>0){
		 	double xCoord = xStart + mc[i].x*step;
		 	double yCoord = yStart - mc[i].y*step;
		 	maximums.push_back(Position<double>(xCoord,yCoord));	
		 }
	}
	//displayMat(binaryMap);
	return maximums;
}

Position<double> Localizer::getMotePosition(std::vector<Position<double>> maximums, const FrameMerger::Frame& frame, std::set<short> selectedSlots){
	Position<double> rssiPosition(NAN,NAN);
	Position<double> finalPosition(NAN,NAN);
	std::vector<float> tempRSSIvector = Competition::rssi_fingerprint(frame);
	cv::Mat temp(1 , tempRSSIvector.size() ,  CV_32FC1);
	for(uint i=0; i<tempRSSIvector.size(); i++){
		temp.at<float>(0,i) = tempRSSIvector[i];
	}
	int K=5;
	CvKNearest knn(datas,classes);
	int result = (int)round(knn.find_nearest(temp , K));
	for(uint i=0;i<coordinates.size();i++){
		if(coordinates[i].first == result){
			rssiPosition = Position<double>(-1.0*coordinates[i].second.first,coordinates[i].second.second);
		}
	}
	double minimumDist = 100.0;
	for(auto maxit = maximums.begin(); maxit != maximums.end(); maxit++){
		if(maxit->distance(rssiPosition) < minimumDist){
			minimumDist = maxit->distance(rssiPosition);
			finalPosition = *maxit;
		}
	}
	
	
	return rssiPosition;
}








