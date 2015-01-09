CXX = g++
CXXFLAGS =-ggdb `pkg-config --cflags opencv`
LFLAGS=`pkg-config --libs opencv`

test: PhaseMap2D.cpp Localization2D.cpp PhaseMap2D.hpp Localization2D.hpp Position.cpp test.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LFLAGS)
	
clean:
	rm test *.gch
