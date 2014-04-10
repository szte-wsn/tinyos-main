#!/usr/bin/env python
import matplotlib.pyplot as plt
from datetime import datetime
import sys
import os
if len(sys.argv) < 2:
  maxtime = 0;
  for f in os.listdir('.'):
    if os.path.isfile(f) and os.path.basename(f).endswith(".csv"):
      if os.path.getmtime(f) > maxtime:
        maxtimes = [os.path.getmtime(f)]
        filenames = [os.path.basename(f)]
else:
  filenames = sys.argv[1:]
index=0;
for filename in filenames:
  LENGTHFREQ=62500
  f = open(filename, 'r')
  data = False
  title=""
  length=0
  while not data:
    line = f.readline().strip('\n')
    if line.startswith("Timestamp"):
      [name, timestamp] = line.split(',')
      title += "&" + timestamp.strip()
    if line.startswith("NodeId"):
      [name, nodeid] = line.split(',')
      title += "#" + nodeid.strip()
    if line.startswith("Sender"):
      [name, nodeid1, nodeid2] = line.split(',')
      title += " (" + nodeid1.strip() + ";" + nodeid2.strip() + ")"
      
    if line.startswith("MeasureTime"):
      [name, measuretime] = line.split(',')
      length = int(measuretime)
      
    if line.startswith("--"):
      data = True
    else:
      print(line)
  xlist = []
  ylist = []
  zlist = []
  timelist = []
  counter = 0;
  for line in f:
    ylist.append(line)
    counter+=1
  f.close()
  if length == 0:
    length = counter
  print(" "+str(length)+" "+str(counter))
  timeusbase=length/counter
  #print(counter)
  #print(length)
  #print(lengthus)
  #print(timeusbase)
  for i in range(0, counter):
    timelist.append(i*timeusbase)
  plt.figure(index);
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
  plt.title(title)
  plt.xlabel('time [us]')
  plt.ylabel('RSSI')
  plt.draw()
  index+=1
plt.show()