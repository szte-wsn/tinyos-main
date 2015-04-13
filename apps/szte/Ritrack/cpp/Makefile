# TODO: use -DNDEBUG in CXXFLAGS to disable asserts for the release

CXX = g++
CXXFLAGS = -std=c++11 -Wall -O3 -MMD
LDFLAGS = -pthread
SOURCES = $(wildcard *.cpp)
DEPENDS = ${SOURCES:.cpp=.d}

OPENCVCFLAGS = -ggdb `pkg-config --cflags opencv`
OPENCVLFLAGS = `pkg-config --libs opencv`

all: recorder phaseplot dump dump2 test test2 testRSSIFilter xfilter testLocalizer

testLocalizer: testLocalizer.cpp Localizer.cpp Config.o Mote.o Position.o PhaseCalculator.o block.o serial.o packet.o filter.o
	$(CXX) $(CXXFLAGS) $(OPENCVCFLAGS) -o $@ $^ $(LDFLAGS) $(OPENCVLFLAGS)

xfilter: xfilter.o block.o serial.o packet.o filter.o
	$(CXX) $(LDFLAGS) -o $@ $^

testRSSIFilter: testRSSIFilter.o block.o serial.o packet.o
	$(CXX) $(LDFLAGS) -o $@ $^

test: test.o Localizer.cpp Config.o Mote.o Position.o PhaseCalculator.o block.o serial.o packet.o viterbi.o filter.o
	$(CXX) $(CXXFLAGS) $(OPENCVCFLAGS) -o $@ $^ $(LDFLAGS) $(OPENCVLFLAGS)

test2: test2.o block.o serial.o packet.o viterbi.o filter.o
	$(CXX) $(LDFLAGS) -o $@ $^

dump: dump.o block.o serial.o packet.o
	$(CXX) $(LDFLAGS) -o $@ $^

dump2: dump2.o block.o serial.o packet.o filter.o
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
	$(RM) recorder phaseplot dump dump2 test test2 testRSSIFilter xfilter ${SOURCES:.cpp=.o} $(DEPENDS)

socat:
	socat -d -d STDIO PTY
