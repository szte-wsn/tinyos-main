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

		Position<DATA> operator+(const Position<DATA>& o) const {
			return Position<DATA>(x + o.x, y + o.y);
		}
		
		Position<DATA> operator-(const Position<DATA>& o) const {
			return Position<DATA>(x - o.x, y - o.y);
		}
		
		DATA distance(const Position<DATA>& o) const{
			Position<DATA> pos(o-(*this));
			return (DATA)sqrt(pos.x*pos.x + pos.y*pos.y);
		}
		DATA angle(const Position<DATA>& o) const{
			Position<DATA> pos(o-(*this));
			return (DATA)atan2(pos.y,pos.x);
		}
		Position<DATA> rotatedPosition(const Position<DATA>& o, const DATA& angle) const{
			DATA distance = this->distance(o);
			DATA angleDiff = this->angle(o);
			return Position<DATA>(this->x+distance*cos(angle+angleDiff),this->y+distance*sin(angle+angleDiff));
		}
		
	friend std::ostream& operator<<(std::ostream& os, const Position<DATA>& pos){
		os << "("<< std::setw(4) << pos.x << " , " << std::setw(4) << pos.y <<")";
		return os;
	}
};

#endif
