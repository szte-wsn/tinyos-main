#include "Mote.hpp"

Mote::Mote(short ID_in, Position<double>& pos_in): ID(ID_in), pos(pos_in){
}

Mote::Mote(const short ID_in, const double x, const double y): ID(ID_in), pos(x,y){
}
	
const short Mote::getID() const { return Mote::ID; }
	
	
const Position<double>& Mote::getPosition() const { return Mote::pos; }

void Mote::setPosition(const Position<double>& pos_in){ 
	Mote::pos.setX(pos_in.getX());
	Mote::pos.setY(pos_in.getY());
}
void Mote::setPosition(const double& x, const double& y){	
	Mote::pos.setX(x);
	Mote::pos.setY(y);
}

std::ostream& operator<<(std::ostream& os, const Mote& mote){
	os << std::setw(2) << mote.ID << ": " << mote.pos;
}

Mote& Mote::operator=(Mote& other){
	this->pos = other.getPosition();
	this->ID = other.getID();
	return *this;
}

bool Mote::operator==(const Mote& other) const{
	return (other.getID() == this->ID);
}

bool Mote::operator!=(const Mote& other) const{
	return (other.getID() != this->ID);
}

bool Mote::operator<(const Mote& other) const{
	return (other.getID() < this->ID);
}
