#!/usr/bin/env python
import matplotlib.pyplot as plt
from datetime import datetime
import sys
import os
if len(sys.argv) >= 2:
	filename = sys.argv[1]
else:
	maxtime = 0;
	for f in os.listdir('.'):
		if os.path.isfile(f) and os.path.basename(f).endswith(".txt"):
			if os.path.getmtime(f) > maxtime:
				maxtime = os.path.getmtime(f)
				filename = os.path.basename(f)
	
LENGTHFREQ=62500
(name, sep, length) = filename.rpartition('.')[0].rpartition('_')
f = open(filename, 'r')
xlist = []
ylist = []
zlist = []
timelist = []
counter = 0;
for line in f:
  ylist.append(line)
  counter+=1
lengthus=1000000*int(length)/LENGTHFREQ
timeusbase=lengthus/counter
#print(counter)
#print(length)
#print(lengthus)
#print(timeusbase)
for i in range(0, counter):
	timelist.append(i*timeusbase)
plt.plot(timelist, ylist)
#fig, ax = plt.subplots()
#ax.plot(timelist, xlist, label="X")
#ax.plot(timelist, ylist, label="Y")
#ax.plot(timelist, zlist, label="Z")
#font = {'family' : 'normal',
        #'weight' : 'bold',
        #'size'   : 18}
#plt.rc('font', **font)
#legend = ax.legend(prop={'size':30})
#legend = ax.legend()
plt.title(name)
plt.xlabel('time [us]')
plt.ylabel('RSSI')
plt.show()