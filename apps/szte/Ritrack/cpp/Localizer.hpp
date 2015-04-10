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
#include "filter.hpp"


class Localizer : public Block{

private:
	float xStart, xEnd, yStart, yEnd;
	float step;
	cv::Mat locationMap;
	cv::Mat binaryMap;
	cv::Mat mask;
	Config& config;
	unsigned short mobileId;
	Mote mobileMote;
	
	void decode(const FrameMerger::Frame &frame);
	
	cv::Mat* getCorrelationMap(const FrameMerger::Frame& frame);
	std::vector<Position<double>> getMaximumPositions();
	Position<double> getMotePosition(std::vector<Position<double>> maximums,const FrameMerger::Frame& frame);

public:
	Input<FrameMerger::Frame> in;
	Output<Position<double>> out;
		
	Localizer(Config& config, float step_in=0.01, float xStart_in=0.0, float yStart_in=10.0, float xEnd_in=10.0, float yEnd_in=0.0);

};

#endif //LOCALIZER_HPP
