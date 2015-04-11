#ifndef LOCALIZER_HPP
#define LOCALIZER_HPP

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/contrib/contrib.hpp>
#include "opencv2/imgproc/imgproc.hpp"
#include "PhaseCalculator.hpp"
#include "Position.hpp"
#include "Config.hpp"
#include "Mote.hpp"
#include <vector>
#include <map>
#include <set>
#include "filter.hpp"
#include <opencv2/ml/ml.hpp>


class Localizer : public Block{

private:
	float xStart, xEnd, yStart, yEnd;
	float step;
	cv::Mat locationMap;
	cv::Mat binaryMap;
	cv::Mat mask;
	Config config;
	unsigned short mobileId;
	Mote mobileMote;
	
	std::vector<std::pair<uint,uint>> boxPairs;
	std::vector<uint> maxRSSIs;
	std::vector<std::pair<int,std::pair<float,float>>> coordinates;
	
	void decode(const FrameMerger::Frame &frame);
	CvKNearest knn;
	
	std::set<short> getSelectedSlots(const FrameMerger::Frame& frame);
	cv::Mat* getCorrelationMap(const FrameMerger::Frame& frame, std::set<short> selectedSlots);
	std::vector<Position<double>> getMaximumPositions();
	Position<double> getMotePosition(std::vector<Position<double>> maximums,const FrameMerger::Frame& frame,std::set<short> selectedSlots);

public:
	Input<FrameMerger::Frame> in;
	Output<Position<double>> out;
		
	Localizer(float step_in=0.01, float xStart_in=0.0, float yStart_in=10.0, float xEnd_in=10.0, float yEnd_in=0.0);

};

#endif //LOCALIZER_HPP
