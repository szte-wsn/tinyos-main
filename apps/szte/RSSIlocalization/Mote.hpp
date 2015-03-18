#ifndef MOTE_HPP
#define MOTE_HPP

#include "Position.hpp"
#include <iostream>
#include <iomanip>

class Mote{

private:
	short ID;
	Position<double> pos;
	
public:
	Mote(short ID_in, Position<double>& pos_in);
	Mote(const short ID_in, const double x, const double y);
	short getID() const;	
	const Position<double>& getPosition() const;
	void setPosition(const Position<double>& pos_in);
	void setPosition(const double& x, const double& y);
	
	Mote& operator=(Mote& other);
	bool operator==(const Mote& other) const;
	bool operator!=(const Mote& other) const;
	bool operator<(const Mote& other) const;
	friend std::ostream& operator<<(std::ostream& os, const Mote& mote);
};

#endif
