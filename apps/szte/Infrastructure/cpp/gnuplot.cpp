#include <iostream>
#include <stdio.h>
#include <cstdlib>
#include <unistd.h>     // usleep
#include <list>
#include <random>
#include <sstream>

using namespace std;

int main(int argc, char* argv[]){
	
	int numberOfMotes = 6;
	int cnt_x = 0;
	int xViewRange = 30;	//for animation
	bool animation = bool(atoi(argv[1]));	//do you need animation
	int animationSpeed = atoi(argv[2]);	//animation speed in us example - 50000
	
	FILE *pipe = popen("gnuplot -persist", "w"); // open pipe to gnuplot
	fprintf(pipe, "\n");
	fprintf(pipe, "reset\n");
	fprintf(pipe, "set terminal wxt size 800,800\n");
	fprintf(pipe, "set ytics 1 font \",16\"\n");
	if(animation)
		fprintf(pipe, "set xrange [0:%d]\n",xViewRange);
	else
		fprintf(pipe, "set autoscale x\n");
	fprintf(pipe, "set yrange [-0.5:%f]\n",(numberOfMotes-0.5));
	fprintf(pipe, "set ytics ( \"4\" 0, \"5\" 1, \"6\" 2, \"7\" 3 , \"8\" 4, \"9\" 5, \"10\" 6, \"11\" 7, \"12\" 8, \"13\" 9, \"14\" 10, \"15\" 11, \"16\" 12, \"17\" 13, \"18\" 14)\n");
	fprintf(pipe, "set xtics 1\n");
	fprintf(pipe, "set noxtics\n");
	fprintf(pipe, "unset autoscale cb\n");
	fprintf(pipe, "set cbrange [0:257]\n");
	fprintf(pipe, "set palette defined (0 \"black\", 6.29 \"white\", 100 \"white\",\\\n");
	fprintf(pipe, "101 \"red\", 102 \"red\",\\\n");
	fprintf(pipe, "102 \"blue\", 103 \"blue\",\\\n");
	fprintf(pipe, "103 '#990099', 104 '#990099',\\\n");
	fprintf(pipe, "104 \"yellow\", 105 \"yellow\",\\\n");
	fprintf(pipe, "105 \"orange\", 106 \"orange\",\\\n");
	fprintf(pipe, "106 \"pink\", 107 \"pink\",\\\n");
	fprintf(pipe, "107 \"white\", 255 \"white\",\\\n");
	fprintf(pipe, "255 \"cyan\", 256 \"cyan\",\\\n");
	fprintf(pipe, "256 \"magenta\", 257 \"magenta\")\n");
	fprintf(pipe, "set ylabel \"Mote IDs\" font \",16\" offset -5	\n");
	fprintf(pipe, "set cblabel \"Phase value\" font \",18\" offset 4\n");
	fprintf(pipe, "unset key\n");
	fprintf(pipe, "set size square\n");
	fprintf(pipe, "set rmargin 10\n");
	fprintf(pipe, "set title \"Relative Phase Map\" font \",20\"\n");
	fprintf(pipe, "set pm3d map\n");
	fprintf(pipe, "splot \"-\" with image \n");
	std::string st = "";
	st = "1 4 4\n1 5 5\n1 6 6\n1 7 7\n1 8 8\n1 9 9	\n1 10 10\n1 11 11\n2 4 4\n2 5 5\n2 6 6\n2 7 7\n2 8 8\n2 9 9\n2 10 10\n2 11 11\ne\n";	//for avoid warning
	fprintf(pipe, "%s",st.c_str());
	fflush(pipe);
	std::string line;
	int k = 0;
	st = "";
	while(std::getline(cin, line)) {
		if(animation) {
			if (cnt_x > xViewRange) {
				for(int i=0; i<numberOfMotes; i++) {
						st.erase(0, (st.find("\n")+1));	//one row length = find("\n") + 1
				}
				char gnuCommand[100];
				sprintf(gnuCommand, "set xrange [%d:%d]\n", (cnt_x-xViewRange+1),cnt_x);
				fprintf(pipe, "%s",gnuCommand);
			}
			fprintf(pipe,"replot\n");
		}
		k = 0;
		std::stringstream ss(line);
		std::string buf;
		while (ss >> buf) {
			char ch[50];
			sprintf(ch,"%d %d ", cnt_x, k++);
			buf.insert(0,ch);
			buf.append("\n");
			st.append(buf);
		}
		cnt_x++;
		if(animation) {
			fprintf(pipe,"%s",st.c_str());
			fprintf(pipe,"e\n");
			fflush(pipe);
			usleep(animationSpeed);
		}
	}
	if(!animation) {
		fprintf(pipe,"replot\n");
		fprintf(pipe,"%s",st.c_str());
		fprintf(pipe,"e\n");
	}
	
	fclose(pipe);
	return 0;
}
