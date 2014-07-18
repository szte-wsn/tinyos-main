#!/usr/bin/env python
from datetime import datetime
from numpy import fft
import struct
import sys
import os
import numpy as np #mathematical library for calculating with the values
import matplotlib.pyplot as plt #plotter
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
  
  #plot
#  plt.figure('Time ' + str(index));
#  plt.plot(timelist, valuelist)
#  plt.title(title)
#  plt.xlabel('time [us]')
#  plt.ylabel('RSSI')
#  plt.xlim(min(timelist),max(timelist))
#  plt.ylim(min(valuelist)-1,max(valuelist)+1)
     

  FFT = fft.fft(valuelist)/len(valuelist);
  freq = fft.fftfreq(len(FFT),d=(timelist[1]-timelist[0]));

  Fkabs= np.absolute(FFT)**2 ##Power spectrum
  phase = np.angle(FFT,deg=False);
#  print("FFT max value,freq,phase(np.angle): "+str(max(Fkabs))+",\t"+str(freq[np.argmax(Fkabs)])+",\t"+str(phase[np.argmax(Fkabs)]))
#  phase = np.arctan2(np.sin(valuelist),np.cos(valuelist));

  ptime.append(index)
  pvalue.append(phase[np.argmax(Fkabs)])

#  print("FFT max value,freq,phase(np.arctan2)): "+str(max(Fkabs))+",\t"+str(freq[np.argmax(Fkabs)])+",\t"+str(phase[np.argmax(Fkabs)]))
  
  #Draw measure FFT and phase
#  plt.figure("Power Spectrum and Phase " + str(filename))
#  plt.subplot(3, 1, 1)
#  plt.plot(timelist, valuelist)
#  plt.title('Measure')
#  plt.xlabel('time [us]')
#  plt.ylabel('Amplitude')
#  plt.xlim(min(timelist),max(timelist))
#  plt.ylim(min(valuelist)-1,max(valuelist)+1)

#  plt.subplot(3, 1, 2)
#  plt.plot(freq, Fkabs, 'r.-')
#  plt.xlabel('freq [Hz]')
#  plt.ylabel('Power Amplitude')
#  plt.xlim(min(freq),max(freq))
#  plt.ylim(min(Fkabs),max(Fkabs))

#  plt.subplot(3, 1, 3)
#  plt.plot(freq, phase, 'r.-')
#  plt.xlabel('freq [Hz]')
#  plt.ylabel('Wrap Phase')

#  plt.draw()
  index+=1  
  print("Calculated Frequency: " + str(freq[np.argmax(Fkabs)]))
  print("Calculated Phase: " + str(phase[np.argmax(Fkabs)]))  
  print("\n\n")

plt.figure("All calculated phase " + str(nodeid))
plt.subplot(2, 1, 1)
plt.plot(ptime,pvalue)
plt.xlabel('time')
plt.ylabel('wrap phase')
uwphase = np.unwrap(pvalue)
plt.subplot(2, 1, 2)
plt.plot(ptime,uwphase)
plt.xlabel('time')
plt.ylabel('unwrap phase')

plt.show()

