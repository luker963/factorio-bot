#pragma once
#include <string>
#include <type_traits>
#include "util.hpp"

constexpr int tileidx(int x)
{
	return ((x % 32) + 32) % 32;
}

constexpr int chunkidx(int x)
{
	return (x>=0) ? x/32 : (x-31)/32;
}

template<typename T>
struct Pos_
{
	T x,y;
	Pos_(T x_, T y_) : x(x_), y(y_) {}
	Pos_() : x(0), y(0) {}

	Pos_<T> operator+(const Pos_<T>& b) const { return Pos_<T>(x+b.x, y+b.y); }
	Pos_<T> operator-(const Pos_<T>& b) const { return Pos_<T>(x-b.x, y-b.y); }
	Pos_<T> operator*(T f) const { return Pos_<T>(x*f, y*f); }
	
	
	Pos_<T> operator/(T f) const;

	bool operator==(const Pos_<T> that) const
	{
		return this->x == that.x && this->y == that.y;
	}

	bool operator< (const Pos_<T>& that) const { return this->x <  that.x && this->y <  that.y; }
	bool operator<=(const Pos_<T>& that) const { return this->x <= that.x && this->y <= that.y; }
	bool operator> (const Pos_<T>& that) const { return this->x >  that.x && this->y >  that.y; }
	bool operator>=(const Pos_<T>& that) const { return this->x >= that.x && this->y >= that.y; }

	std::string str() const { return std::to_string(x) + "," + std::to_string(y); }

	static Pos_<T> tile_to_chunk(const Pos_<T>& p) { return Pos_<T>(chunkidx(p.x), chunkidx(p.y)); }
	static Pos_<T> tile_to_chunk_ceil(const Pos_<T>& p) { return Pos_<T>(chunkidx(p.x+31), chunkidx(p.y+31)); }
};

template <> inline Pos_<int> Pos_<int>::operator/(int f) const { return Pos_<int>(sane_div(x,f), sane_div(y,f)); }
template <> inline Pos_<double> Pos_<double>::operator/(double f) const { return Pos_<double>(x/f,y/f); }

typedef Pos_<int> Pos;
typedef Pos_<double> Pos_f;
