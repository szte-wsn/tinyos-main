#include "Localizer.hpp"

void displayMat(cv::Mat& mat){
	cv::Mat display(mat.size(),CV_8UC1);
	double min, max;
	cv::minMaxLoc(mat, &min, &max);
	mat.convertTo(display, CV_8UC1, 255.0 / max, 0);
	applyColorMap(display, display, cv::COLORMAP_SUMMER);
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

Localizer::Localizer(Config& config_in, float step_in, float xStart_in, float yStart_in, float xEnd_in, float yEnd_in)
	: config(config_in), mobileMote(-1,0.0,0.0), in(bind(&Localizer::decode, this))
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
	std::vector<Mote>& mobileMote = config.getMobiles();
	if(mobileMote.size() != 1){
		std::cerr << "This version can only handle one mobile mote!" << std::endl;
		throw std::runtime_error("Too many mobile motes.");
	}else{
		Localizer::mobileId = mobileMote[0].getID();
		Localizer::mobileMote = mobileMote[0];
	}
}

void Localizer::decode(const FrameMerger::Frame &frame){
	getCorrelationMap(frame);  //uses locationMap
	displayMat(locationMap);
	std::vector<Position<double>> maximums = getMaximumPositions(); //uses locationMap
	Position<double> maxPos = getMotePosition(maximums,frame);
	out.send(maxPos);
}

cv::Mat* Localizer::getCorrelationMap(const FrameMerger::Frame& frame){
	Localizer::locationMap.setTo(cv::Scalar(0.0));
	std::cout << frame << std::endl;
	for(auto slotit = frame.slots.begin(); slotit!=frame.slots.end(); slotit++){
		if(slotit->get_data(mobileId) == NULL){
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
	return &locationMap;			
}


std::vector<Position<double>> Localizer::getMaximumPositions(){
	double min, max, thres=0.95;
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
	displayMat(binaryMap);
	std::vector<std::vector<cv::Point> > contours;
	cv::findContours( binaryMap, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE );
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
	displayMat(binaryMap);
	return maximums;
}

Position<double> Localizer::getMotePosition(std::vector<Position<double>> maximums, const FrameMerger::Frame& frame){
	//which is the nearest tx based on RSSI
	unsigned short nearestID = 255;
	unsigned short maxRSSI = 0;
	for(auto slotit = frame.slots.begin(); slotit!=frame.slots.end(); slotit++){
		if(slotit->get_data(mobileId) == NULL){
			continue;
		}
		if(slotit->get_data(mobileId)->rssi1 >= maxRSSI){
			maxRSSI = slotit->get_data(mobileId)->rssi1;
			nearestID = slotit->sender1;
		}
	}
	Mote nearestTx = config.getStable(nearestID);
	//which is the nearest maxima from this tx
	Position<double> nearestPosition(NAN,NAN);
	double minDistance = 1000.0;
	for(auto maxit = maximums.begin(); maxit!=maximums.end();maxit++){
		double dist = nearestTx.getPosition().distance(*maxit);
		if(dist < minDistance){
			minDistance = dist;
			nearestPosition = *maxit;
		}
	}
	return nearestPosition;
}








