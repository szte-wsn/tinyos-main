CXX = g++
CXXFLAGS = -std=c++11 -O3 -Wall -MMD
LDFLAGS = -pthread
SOURCES = $(wildcard *.cpp)
DEPENDS = ${SOURCES:.cpp=.d}

all: recorder phaseplot dump test test2 xfilter

xfilter: xfilter.o block.o serial.o packet.o filter.o
	$(CXX) $(LDFLAGS) -o $@ $^

test: test.o block.o serial.o packet.o viterbi.o
	$(CXX) $(LDFLAGS) -o $@ $^

test2: test2.o block.o serial.o packet.o viterbi.o
	$(CXX) $(LDFLAGS) -o $@ $^

dump: dump.o block.o serial.o packet.o
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
	$(RM) test dump recorder phaseplot ${SOURCES:.cpp=.o} $(DEPENDS)

socat:
	socat -d -d STDIO PTY
