CXX = g++
CXXFLAGS = -std=c++11 -O3 -Wall -MMD
LDFLAGS = -pthread
SOURCES = $(wildcard *.cpp)
DEPENDS = ${SOURCES:.cpp=.d}

all: recorder phaseplot test

test: test.o block.o serial.o packet.o
	$(CXX) $(LDFLAGS) -o $@ $^

recorder: recorder.o block.o serial.o
	$(CXX) $(LDFLAGS) -o $@ $^

phaseplot: phaseplot.o
	$(CXX) $(LDFLAGS) -o $@ $^

.cpp.o:
	$(CXX) $(CXXFLAGS) -c $<

-include ${DEPENDS}

.PHONY: clean socat

clean:
	$(RM) test recorder phaseplot *.o *.d

socat:
	socat -d -d STDIO PTY
