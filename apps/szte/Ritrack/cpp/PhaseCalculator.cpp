#include "PhaseCalculator.hpp"


const double PhaseCalculator::PERIODTOLERANCE = 4.0;

double PhaseCalculator::absPhase(const Position<double>& p1, const Position<double>& p2){
	return fmod(TWOPi_per_lambda_carrier * p1.distance(p2),TWOpi);
}

double PhaseCalculator::phaseDiff(const double& ph1, const double& ph2){
	double ret = fmod(ph1-ph2,TWOpi);
	if(ret < 0)
		return TWOpi+ret;
	return ret;
}

double PhaseCalculator::relPhase(const short& ref_phase,const short& ref_period,const short& other_phase,const short& other_period){
	if( ref_phase == NAN || ref_period == NAN || other_phase == NAN || other_period == NAN || ref_period == 0 || other_period==0)
		return NAN;
	if( std::abs(ref_period-other_period) > PhaseCalculator::PERIODTOLERANCE){
		return NAN;
	}else{
		//double phaseDiff = (TWOpi*ref_phase)/ref_period - (TWOpi*other_phase)/other_period;
		double avg_period = (ref_period+other_period)/2.0;
		double ret = fmod(((ref_phase-other_phase)/avg_period)*TWOpi, TWOpi);
		if(ret < 0)
			return TWOpi+ret;
		return ret;
	}
}

double PhaseCalculator::phaseCorrelation(const double& phase1, const double& phase2){
	if( phase1==NAN || phase2==NAN){
		return 0.0;
	}
	return cos(phase1-phase2)+1.0;
}
