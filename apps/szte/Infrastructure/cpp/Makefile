CXX = g++
CXXFLAGS = -std=c++11 -O3 -Wall -MMD
LDFLAGS = -pthread
SOURCES = $(wildcard *.cpp)
DEPENDS = ${SOURCES:.cpp=.d}

all: recorder test

test: test.o block.o serial.o
	$(CXX) $(LDFLAGS) -o $@ $^

recorder: recorder.o block.o serial.o
	$(CXX) $(LDFLAGS) -o $@ $^

.PHONY: clean socat

clean:
	$(RM) test *.o *.d

socat:
	socat -d -d STDIO PTY

.cpp.o:
	$(CXX) $(CXXFLAGS) -c $<

-include ${DEPENDS}
