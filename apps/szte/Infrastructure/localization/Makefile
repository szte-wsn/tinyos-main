CXX = g++
CXXFLAGS =-ggdb `pkg-config --cflags opencv` -std=c++11
LFLAGS=`pkg-config --libs opencv`

test2: test2.cpp Config.cpp Mote.cpp Position.hpp Measurement.cpp Localization2D.cpp InputParser.cpp PhaseCalculator.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)
	
test: test.cpp Config.cpp Mote.cpp Position.hpp Measurement.cpp Localization2D.cpp InputParser.cpp PhaseCalculator.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)

testKNN: testKNN.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)

clean:
	rm -f test2 test *.gch *.o
