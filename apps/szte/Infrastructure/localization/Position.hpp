#ifndef POSITION_HPP
#define POSITION_HPP

#include <iostream>
#include <iomanip>
#include <cmath>

template <class DATA>
class Position{
	private:
		DATA x,y;
	public:
	 	Position( const DATA& x_in, const DATA& y_in): x(x_in), y(y_in){
		}
	 	Position( const Position<DATA>& pos_in): x(pos_in.x), y(pos_in.y){
		}
		const DATA getX() const { return x; }
		const DATA getY() const { return y; }
		void setX(const DATA& x_in){ x = x_in; }
		void setY(const DATA& y_in){ y = y_in; }
		
		Position<DATA>& operator=(const Position<DATA>& other){
			this->x = other.getX();
			this->y = other.getY();
			return *this;
		}
		
	friend std::ostream& operator<<(std::ostream& os, const Position<DATA>& pos){
		os << "("<< std::setw(4) << pos.x << " , " << std::setw(4) << pos.y <<")";
		return os;
	}
};

double distance(const Position<double>& a, const Position<double>& b);
double angle(const Position<double>& ref, const Position<double>& other);

#endif
