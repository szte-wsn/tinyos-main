#!/usr/bin/env python
from datetime import datetime
from numpy import fft
import struct
import sys
import os
import numpy as np #mathematical library for calculating with the values
import matplotlib.pyplot as plt #plotter
from decimal import Decimal
LENGTHFREQ=62500

if len(sys.argv) < 2: #no argument was given, use the newest file
  allfilenames = []
  for f in os.listdir('.'):
    if os.path.isfile(f) and os.path.basename(f).endswith(".raw"):
      allfilenames.append(f)
  filenames = [max(allfilenames)]
else:
  filenames = sys.argv[1:]


index=0;
ptime = []
pvalue = []
relPhase = {}
for filename in filenames:
  f = open(filename, 'rb')
  
  #reading the main data
  arraylength = struct.unpack('>I', f.read(4))[0]
  values = struct.unpack('>'+str(arraylength)+'s',f.read(arraylength))[0]
  
  #reading result_t:
  #typedef nx_struct result_t{
    #nx_uint16_t measureTime;
    #nx_uint32_t period;
    #nx_uint32_t phase;
    #//debug only:
    #nx_uint8_t channel;
    #nx_uint16_t senders[2];
    #nx_int8_t fineTunes[2];
    #nx_uint8_t power[2];
    #nx_uint16_t selfNodeId;
    #nx_uint16_t measureId;
  #} result_t;
  #plus, there's an 8 byte java timestamp at the end
  measureTime, period, phase, channel, sender1, sender2, fineTune1, fineTune2, power1, power2, nodeid, measureId, timestamp  = struct.unpack('>HIIBHHbbBBHHQ', f.read(31))
  f.close()
  

  #print data
  print(sys.version_info.major)
  print("Read Values from file: " + filename)
  print("NodeId: "+str(nodeid))
  print("MeasureId: "+str(measureId))
  print("TimeStamp: "+str(timestamp/1000)+" "+str(datetime.fromtimestamp(timestamp/1000)))
  print("Arraylength: "+str(arraylength))
  print("Period: "+str(period))
  print("Phase: "+str(phase))
  print("MeasureTime: "+str(measureTime))
  print("Channel: "+str(channel))
  print("Senders: "+str(sender1)+", "+str(sender2))
  print("FineTune: "+str(fineTune1)+", "+str(fineTune2))
  print("Power: "+str(power1)+", "+str(power2))
  
  #set up the title
  title = datetime.fromtimestamp(timestamp/1000).strftime("&%m.%d. %H:%M:%S.%f")[:-3]
  title += " #"+str(measureId)+"/"+str(nodeid)
  title += " ("+str(sender1)+", "+str(sender2)+")"
  
  #set up the time axis, and convert the value axis to integer
  timelist = []
  valuelist = []
  timeusbase=measureTime/arraylength
  for i in range(0, arraylength):
    timelist.append(i*timeusbase)
    if( sys.version_info.major < 3):
      valuelist.append(ord(values[i]))
    else:
      valuelist.append(values[i])

  #Select only the measure
  fftvaluelist = []
  ffttimelist = []
  k = 0;

  for i in valuelist:
    if i > 5:
      fftvaluelist.append(i) 
  fftvaluelist = fftvaluelist[1:-2]    

  ffttimeusbase=measureTime/len(fftvaluelist)
  for i in range(0, len(fftvaluelist)):
    ffttimelist.append(i*ffttimeusbase)

  mean = np.mean(fftvaluelist)
  fftvaluelist = fftvaluelist - mean

  valuelist = fftvaluelist
  timelist = ffttimelist
     
  #Calc FFT
  FFT = fft.fft(valuelist)/len(valuelist);
  freq = fft.fftfreq(len(FFT),d=(timelist[1]-timelist[0]));

  Fkabs= np.absolute(FFT)**2 ##Power spectrum

  #Select how to calc phase:
    
  phase = np.angle(FFT,deg=False);
#  phase = np.arctan2(np.sin(valuelist),np.cos(valuelist));

  ptime.append(index)
  pvalue.append(phase[np.argmax(Fkabs)])


  word = filename.split('_')
  relPhase.setdefault(word[0], [])
  relPhase[word[0]].append(phase[np.argmax(Fkabs)])
  
  index+=1  
  print("Calculated Frequency: " + str(freq[np.argmax(Fkabs)]))
  print("Calculated Phase: " + str(phase[np.argmax(Fkabs)]))  
  print("\n\n")

index = 0
relTime = []
relValues = []
print("Keys len: " + str(len(relPhase.keys())))
for key in sorted(relPhase.keys()):
  tmpValues = relPhase.get(key)
#  print(str(key) + " ")
  if len(tmpValues) > 1:
    tmp = tmpValues[0]-tmpValues[1]
#    print(str(tmpValues) + " ")
#    for val in range(1,len(tmpValues)):
#      tmp = tmp-val
#    print(str(tmp) + " ")
    relValues.append(tmp)
    relTime.append(index)
    index+=1

#print("RealValues: " + str(relValues))
plt.figure("Relative phase")
plt.subplot(2, 1, 1)
plt.plot(relValues)
plt.xlabel('time')
plt.ylabel('wrap phase')
uwphase = np.unwrap(relValues)
plt.subplot(2, 1, 2)
plt.plot(uwphase)
plt.xlabel('time')
plt.ylabel('unwrap phase')


plt.show()

