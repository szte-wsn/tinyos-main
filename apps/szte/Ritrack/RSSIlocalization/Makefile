CXX = g++
CXXFLAGS =-ggdb `pkg-config --cflags opencv` -std=c++11
LFLAGS=`pkg-config --libs opencv`

test2: test2.cpp Config.cpp Mote.cpp Position.hpp Measurement.cpp Localization2D.cpp InputParser.cpp PhaseCalculator.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)
	
testInputParser: testInputParser.cpp Measurement.cpp InputParser.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)

testKNN: testKNN.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)
	
filter: filter.cpp Measurement.cpp InputParser.cpp RSSIFilter.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)
	
fingerprinter: fingerprinter.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)
	
localizer: localizer.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)

clean:
	rm test2 testInputParser testKNN *.gch *.o
