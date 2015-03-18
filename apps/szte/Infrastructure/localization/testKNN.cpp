#include <opencv2/highgui/highgui.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/ml/ml.hpp>

int main(){
	int K=1;
	int sample_count = 3;
	cv::Mat trainData( sample_count, 2, CV_32FC1 );
	cv::Mat trainClasses( sample_count, 1, CV_32FC1 );
	
	trainData.at<float>(0,0) = 0.0;
	trainData.at<float>(0,1) = 0.0;
	trainData.at<float>(1,0) = 5.0;
	trainData.at<float>(1,1) = 5.0;
	trainData.at<float>(2,0) = 10.0;
	trainData.at<float>(2,1) = 10.0;
	
	trainClasses.at<float>(0) = 0.0;
	trainClasses.at<float>(1) = 1.0;
	trainClasses.at<float>(2) = 2.0;
	
	CvKNearest knn(trainData,trainClasses);
	
	cv::Mat sample( 1, 2, CV_32FC1 );
	sample.at<float>(0,0) = 10.0;
	sample.at<float>(0,1) = 1.0;
	
	float result = knn.find_nearest(sample , K);
	
	std::cout << result << std::endl;
	
	return 0;
}
