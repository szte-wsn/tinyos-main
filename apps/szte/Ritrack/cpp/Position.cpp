#ifndef POSITION_HPP
#define POSITION_HPP

template <class DATA>
class Position{
	private:
		DATA x,y;
	public:
	 	Position( const DATA& x_in = 0 , const DATA& y_in = 0) : x(x_in), y(y_in){
		}
		DATA getX(){ return x; }
		DATA getY(){ return y; }
		void setX(const DATA& x_in){ x = x_in; }
		void setY(const DATA& y_in){ y = y_in; }
	friend class PhaseMap2D;
	friend class Localization2D;
};

#endif
