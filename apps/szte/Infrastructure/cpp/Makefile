CXX = g++
CXXFLAGS = -std=c++11 -pthread -O3 -Wall -MMD
SOURCES = $(wildcard *.cpp)
DEPENDS = ${SOURCES:.cpp=.d}

all: test

test: test.o block.o serial.o compat.o
	$(CXX) -o $@ $^

clean:
	$(RM) test *.o *.d

.cpp.o:
	$(CXX) $(CXXFLAGS) -c $<

-include ${DEPENDS}
