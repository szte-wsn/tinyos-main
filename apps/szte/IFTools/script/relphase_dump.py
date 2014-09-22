#!/usr/bin/env python
from datetime import datetime
import struct
import sys
import os
import numpy #mathematical library for calculating with the values
import matplotlib.pyplot as plt #plotter

class measurement:
  def __init__(self, filename=None):
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
        self.times.append(i*timeusbase)
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
    print("Period: "+str(self.fftperiod))
    print("Phase: "+str(self.fftphase))
    
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
    
    maxAmplitudeIndex = numpy.argmax(amplitudediag[1:signalsize/2])+1
    
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


def savediffs(filenames, outfilename):
  f = open(outfilename, 'w')
  index=0;
  measures=[]
  phasediffs=[]
  prevmeasid=-1
  for filename in filenames:
    m = measurement(filename)
    m.searchEndpoints(5)
    if prevmeasid != m.measureId:
      if prevmeasid != -1:
        for i in range(0, len(measures)):
          for j in range(i+1, len(measures)):
            if measures[i][1]!=1000 and measures[j][1]!=1000:
              phasediffs.append((measures[i][0], measures[j][0], (measures[i][1]-measures[j][1])%360))
        #print(str(prevmeasid)+" "+str(measures))
      prevmeasid = m.measureId
      measures=[]
    try:
      m.calculateFft()
      measureselement=(m.nodeid, m.fftphase)
    except ValueError:
      measureselement=(m.nodeid, 1000)
    measures.append(measureselement)


  while len(phasediffs)>0:
    rx1=phasediffs[0][0]
    rx2=phasediffs[0][1]
    f.write(str(rx1)+"; "+str(rx2))
    removelist=[]
    for phasediff in phasediffs:
      if phasediff[0] == rx1 and phasediff[1] == rx2:
        f.write("; "+"{:3.0f}".format(phasediff[2]))
        removelist.append(phasediff)
    f.write('\n')
    for remove in removelist:
      phasediffs.remove(remove)
  f.close()

for trim in ("trim00", "trim03", "trim06", "trim09", "trim12", "trim15"):
  for ch in ("ch11", "ch14", "ch17", "ch20", "ch23", "ch26"):
    prevmid=""
    filenames = []
    for f in sorted(os.listdir("./"+trim+"/"+ch+"/")):
      #print("./"+trim+"/"+ch+"/"+f)
      mid=os.path.basename(f)[:4]
      filenames.append("./"+trim+"/"+ch+"/"+f)
      #print(mid)
      if mid != prevmid:
        if prevmid != "":
          savediffs(filenames, mid+".csv")
          filenames=[]
        prevmid = mid
            
        #filenames.append(f)
#if len(sys.argv) < 2: #no argument was given, use the newest file
  #allfilenames = []
  #for f in os.listdir('.'):
    #if os.path.isfile(f) and os.path.basename(f).endswith(".raw"):
      #allfilenames.append(f)
  #filenames = [max(allfilenames)]
#else:
  #filenames = sys.argv[1:]