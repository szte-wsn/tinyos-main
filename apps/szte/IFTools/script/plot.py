#!/usr/bin/env python
from datetime import datetime
import struct
import sys
import os
import numpy #mathematical library for calculating with the values
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
for filename in filenames:
  f = open(filename, 'rb')
  
  #reading the main data
  arraylength = struct.unpack('>I', f.read(4))[0]
  if arraylength == 0:
    continue
  values = struct.unpack('>'+str(arraylength)+'s',f.read(arraylength))[0]
  measureTime = struct.unpack('>H', f.read(2))[0];
  #reading result_t:
  #typedef nx_struct result_t{
    #nx_uint16_t meastimeusbase = measureTime/arraylengthureTime;
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
  if measureTime > 100:
    period, phase, channel, sender1, sender2, fineTune1, fineTune2, power1, power2, nodeid, measureId, timestamp  = struct.unpack('>HIIBHHbbBBHHQ', f.read(29))
    f.close()
    

    #print data
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
    timeusbase = measureTime/arraylength
  else:
    title = ""
    timeusbase = 2
   #set up the time axis, and convert the value axis to integer
  timelist = []
  valuelist = []
  for i in range(0, arraylength):
    timelist.append(i*timeusbase)
    if( sys.version_info.major < 3):
      valuelist.append(ord(values[i]))
    else:
      valuelist.append(int(values[i]))
  
  #plot
  plt.figure(index);
  plt.plot(timelist, valuelist)
  plt.title(title)
  plt.xlabel('time [us]')
  plt.ylabel('RSSI')
  plt.draw()
  index+=1
plt.show()