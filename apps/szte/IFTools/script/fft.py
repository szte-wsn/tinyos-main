#!/usr/bin/env python
from datetime import datetime
import struct
import sys
import os
import numpy #mathematical library for calculating with the values
import matplotlib.pyplot as plt #plotter

class measurement:
  def __init__(self, filename=None, realTime = True):
    self.measureId = 0
    self.nodeid = 0
    self.samples = []
    self.measureTime = 0
    self.channel = 0
    self.sender1 = 0
    self.sender2 = 0
    self.fineTune1 = 0
    self.fineTune2 = 0
    self.power1 = 0
    self.power2 = 0
    self.timestamp = 0
    self.period = 0
    self.phase = 0
    self.values = []
    self.times = []
    self.filename = filename
    self.startpoint = 0
    self.endpoint = 0
    self.fftperiod = 0
    self.fftphase = 0
    self.testperiod = 0
    self.testphase = 0
    if filename != None:
      f = open(filename, 'rb')
    
      #reading the main data
      arraylength = struct.unpack('>I', f.read(4))[0]
      chrvalues = struct.unpack('>'+str(arraylength)+'s',f.read(arraylength))[0]
    
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
      self.measureTime, self.period, self.phase, self.channel, self.sender1,\
        self.sender2, self.fineTune1, self.fineTune2, self.power1, self.power2,\
        self.nodeid, self.measureId, self.timestamp  = struct.unpack('>HIIBHHbbBBHHQ', f.read(31))
      f.close()
      
      #set up the time axis, and convert the value axis to integer
      timeusbase=self.measureTime/arraylength
      for i in range(0, arraylength):
        if(realTime):
          self.times.append(i*timeusbase)
        else:
          self.times.append(i)
        if( sys.version_info.major < 3):
          self.values.append(ord(chrvalues[i]))
        else:
          self.values.append(int(chrvalues[i]))
      self.endpoint = len(self.values)
  
  def printData(self):
    print("Read Values from file: " + self.filename)
    print("NodeId: "+str(self.nodeid))
    print("MeasureId: "+str(self.measureId))
    print("TimeStamp: "+str(self.timestamp/1000)+" "+str(datetime.fromtimestamp(self.timestamp/1000)))
    print("Arraylength: "+str(len(self.values)))
    print("MeasureTime: "+str(self.measureTime))
    print("Channel: "+str(self.channel))
    print("Senders: "+str(self.sender1)+", "+str(self.sender2))
    print("FineTune: "+str(self.fineTune1)+", "+str(self.fineTune2))
    print("Power: "+str(self.power1)+", "+str(self.power2))
    print("Received values:")
    print("Period: "+str(self.period))
    print("Phase: "+str(self.phase))
    print("Calculated values:")
    print("Endpoints: "+str(self.startpoint)+" "+str(self.endpoint))
    print("Period (FFT; test; diff): "+str(self.fftperiod)+" "+str(self.testperiod)+" "+str(self.testperiod-self.fftperiod))
    print("Phase (FFT; test; diff): "+str(self.fftphase)+" "+str(self.testphase)+" "+str(self.testphase-self.fftphase))
    
  def plot(self, onlyRealData=True, index=0, show=True):
    #set up the title
    title = datetime.fromtimestamp(self.timestamp/1000).strftime("&%m.%d. %H:%M:%S.%f")[:-3]
    title += " #"+str(self.measureId)+"/"+str(self.nodeid)
    title += " ("+str(self.sender1)+", "+str(self.sender2)+")"
    plt.figure(index);
    plt.plot(self.times[self.startpoint:self.endpoint], self.values[self.startpoint:self.endpoint])
    plt.title(title)
    plt.xlabel('time [us]')
    plt.ylabel('RSSI')
    plt.draw()
    if show:
      plt.show()
    return index+1
  
  def searchEndpoints(self, threshold):
    startpointset = False
    for i in range(0, len(self.values)):
      if not startpointset:
        if self.values[i] >= threshold:
          self.startpoint = i
          startpointset = True
      else:
        if self.values[i] < threshold:
          self.endpoint = i
          break
      
  def calculateFft(self, plotAmplitude = False, index=0, show=True):
    signalsize = len(self.values[self.startpoint:self.endpoint])
    sampletime = (self.measureTime*1e-6)/len(self.values)
    fftres = numpy.fft.rfft(self.values[self.startpoint:self.endpoint])
    frequencies = numpy.fft.rfftfreq(signalsize, sampletime)
    amplitudediag = numpy.absolute(fftres)
    
    maxAmplitudeIndex = numpy.argmax(amplitudediag[1:])+1
    
    self.fftperiod = 1e6/frequencies[maxAmplitudeIndex]
    self.fftphase = numpy.angle(fftres[maxAmplitudeIndex], True)
    
    if plotAmplitude:
      #set up the title
      title = datetime.fromtimestamp(self.timestamp/1000).strftime("&%m.%d. %H:%M:%S.%f")[:-3]
      title += " #"+str(self.measureId)+"/"+str(self.nodeid)
      title += " ("+str(self.sender1)+", "+str(self.sender2)+")"
      title += " Amplitude"
      plt.figure(index);
      plt.plot(frequencies[1:], amplitudediag[1:])
      plt.title(title)
      plt.xlabel('Frequency [Hz]')
      plt.draw()
      index+=1
      if show:
        plt.show()
    return index
  
  def calculateTest(self, leadTime=10):
    #NOTE add algorithm here
    self.phase=0
    self.period=0

if len(sys.argv) < 2: #no argument was given, use the newest file
  allfilenames = []
  for f in os.listdir('.'):
    if os.path.isfile(f) and os.path.basename(f).endswith(".raw"):
      allfilenames.append(f)
  filenames = [max(allfilenames)]
else:
  filenames = sys.argv[1:]


index=0;
for filename in filenames:
  m = measurement(filename, False)
  m.searchEndpoints(2)
  #index = m.calculateFft(True, index, False)
  m.calculateFft()
  m.calculateTest()
  m.printData()
  index = m.plot(True, index, False)
plt.show()
  
