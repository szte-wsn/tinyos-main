/*
 * Copyright (c) 2015, University of Szeged
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Author: Miklos Maroti
 */

#include "miklosloc.hpp"

MiklosLoc::MiklosLoc() {
	std::vector<Competition::TrainingData> training_data;
	Competition::read_training_data(training_data);

	for (const Competition::TrainingData &data : training_data) {
		for (const std::vector<float> &fingerprint : data.fingerprints) {
			cv::Mat temp1(1, fingerprint.size(), CV_32FC1);
			for(uint k = 0; k < fingerprint.size(); k++)
				temp1.at<float>(0, k) = fingerprint[k];
			fingerprints.push_back(temp1.clone());

			cv::Mat temp2(1, 1, CV_32FC1);
			temp2.at<float>(0, 0) = (float)data.id;
			classes.push_back(temp2.clone());
		}

		coordinates[data.id].first = data.x;
		coordinates[data.id].second = data.y;
	}
}

void MiklosLoc::localize(const FrameMerger::Frame &frame, float &x, float &y) {
	std::vector<float> sample = Competition::rssi_fingerprint(frame);

	cv::Mat temp(1, sample.size(),  CV_32FC1);
	for(uint i = 0; i < sample.size(); i++) {
		temp.at<float>(0, i) = sample[i];
	}

	CvKNearest knn(fingerprints, classes);
	int result = (int) round(knn.find_nearest(temp, 5));

	auto it = coordinates.find(result);
	if (it == coordinates.end()) {
		std::cerr << "Invalid class returned" << std::endl;
		return;
	}
	else {
		x = it->second.first;
		y = it->second.second;
	}
}

void MiklosLoc::static_localize(const FrameMerger::Frame &frame, float &x, float &y) {
	if (instance == NULL)
		instance = new MiklosLoc();

	instance->localize(frame, x, y);
}

MiklosLoc *MiklosLoc::instance = NULL;
