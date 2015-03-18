#ifndef PHASE_CALCULATOR_HPP
#define PHASE_CALCULATOR_HPP

#include "Position.hpp"
#include <cmath>

#define c_light 299792458
#define f_carrier 2400000000
#define lambda_carrier 0.12491352416
#define TWOPi_per_lambda_carrier 50.3002805295
#define TWOpi 6.28318530718


class PhaseCalculator{

public:
	const static double PERIODTOLERANCE;
	static double absPhase(const Position<double>& p1, const Position<double>& p2);
	static double relPhase(const short& ref_phase,const short& ref_period,const short& other_phase,const short& other_period);
	static double phaseDiff(const double& ph1, const double& ph2);
	static double phaseCorrelation(const double& phase1, const double& phase2);
};

#endif