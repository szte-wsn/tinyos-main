#!/usr/bin/env python
import matplotlib.pyplot as plt
from datetime import datetime
import sys
f = open(sys.argv[1], 'r')
xlist = []
ylist = []
zlist = []
timelist = []
counter = 0;
for line in f:
  ylist.append(line)
  timelist.append(counter)
  counter+=1

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
name = sys.argv[1].split('.')
plt.title(name[0])
plt.xlabel('time')
plt.ylabel('RSSI')
plt.show()