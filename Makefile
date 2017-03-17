CXX=clang++
CC=clang

#CC=gcc
#CXX=g++

#FLAGS=-Wall -Wextra
FLAGS=-Weverything -Wno-c++98-compat -Wno-c++98-c++11-compat -Wno-sign-conversion -Wno-padded -Wno-exit-time-destructors -Wno-global-constructors -g

CXXFLAGS=-std=c++14 $(FLAGS)

test: factorio_io.o
	$(CXX) $(CXXFLAGS) $^ -o $@

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $^ -o $@
