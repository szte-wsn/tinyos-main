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
  
  #plot
  plt.figure('Time ' + str(index));
  plt.plot(timelist, valuelist)
  plt.title(title)
  plt.xlabel('time [us]')
  plt.ylabel('RSSI')
  plt.xlim(min(timelist),max(timelist))
  plt.ylim(min(valuelist)-1,max(valuelist)+1)

  FFT = fft.fft(valuelist)/arraylength;
  freq = fft.fftfreq(len(FFT),d=(timelist[1]-timelist[0]));

#  FFT = fft.fftshift(FFT);
#  freq = fft.fftshift(freq);

  phase = np.arctan(min(FFT).imag/min(FFT).real)
  print("Phase rad: "+str(phase)+" ,deg: "+str(np.rad2deg(phase)))

  phase = np.angle(FFT,deg=True);
  phase = np.unwrap(phase);

  print("\nFFT size: "+str(len(FFT)))
  print("FFT max value,freq,phase: "+str(max(FFT))+",\t"+str(freq[np.argmax(FFT)])+",\t"+str(phase[np.argmax(FFT)]))
  print("FFT min value,freq,phase: "+str(min(FFT))+",\t"+str(freq[np.argmin(FFT)])+",\t"+str(phase[np.argmin(FFT)]))
  print("FFT_real(cos) max value,freq,phase: "+str(max(np.real(FFT)))+",\t"+str(freq[np.argmax(np.real(FFT))])+",\t"+str(phase[np.argmax(np.real(FFT))]))
  print("FFT_real(cos) min value,freq,phase: "+str(min(np.real(FFT)))+",\t"+str(freq[np.argmin(np.real(FFT))])+",\t"+str(phase[np.argmin(np.real(FFT))]))
  print("FFT_imag(sin) max value,freq,phase: "+str(max(np.imag(FFT)))+",\t"+str(freq[np.argmax(np.imag(FFT))])+",\t"+str(phase[np.argmax(np.imag(FFT))]))
  print("FFT_imag(sin) min value,freq,phase: "+str(min(np.imag(FFT)))+",\t"+str(freq[np.argmin(np.imag(FFT))])+",\t"+str(phase[np.argmin(np.imag(FFT))]))
  print("FFT max real,imag,real_phase,imag_phase: "+str(max(FFT).real)+",\t"+str(max(FFT).imag)+",\t"+str(phase[max(FFT).real])+",\t"+str(phase[max(FFT).imag]))
  print("FFT min real,imag,real_phase,imag_phase: "+str(min(FFT).real)+",\t"+str(min(FFT).imag)+",\t"+str(phase[min(FFT).real])+",\t"+str(phase[min(FFT).imag]))
#  print("Phase rad: "+str(phase));
  print("\n")


  plt.figure('FFT ' + str(index))
  plt.subplot(5, 1, 1)
  plt.plot(timelist, valuelist)
  plt.title('Measure')
  plt.xlabel('time [us]')
  plt.ylabel('Amplitude in time')
  plt.xlim(min(timelist),max(timelist))
  plt.ylim(min(valuelist)-1,max(valuelist)+1)
  
  plt.subplot(5, 1, 2)
  plt.plot(freq, FFT, 'r.-')
  plt.xlabel('freq [Hz]')
  plt.ylabel('Amplitude in freq')
#  plt.xlim(-0.1,0.1)   x tengely hatarai
  plt.ylim(min(FFT)-1,max(FFT)+1)

  plt.subplot(5, 1, 3)
  plt.plot(freq, np.real(FFT), 'r.-')
  plt.xlabel('freq [Hz]')
  plt.ylabel('Real Amplitude')
  plt.ylim(min(np.real(FFT))-1,max(np.real(FFT))+1)

  plt.subplot(5, 1, 4)
  plt.plot(freq, np.imag(FFT), 'r.-')
  plt.xlabel('freq [Hz]')
  plt.ylabel('Imag Amplitude')
  plt.ylim(min(np.imag(FFT))-0.1,max(np.imag(FFT))+0.1)

  Fkabs= np.absolute(FFT)**2 ##Power spectrum
  plt.subplot(5, 1, 5)
  plt.plot(freq, Fkabs, 'r.-')
  plt.xlabel('freq [Hz]')
  plt.ylabel('Power Amplitude')
  plt.ylim(min(Fkabs)-10,max(Fkabs)+10)

  plt.subplot(6, 1, 6)
  plt.plot(freq, phase, 'r.-')
  plt.xlabel('freq [Hz]')
  plt.ylabel('Phase')

  plt.draw()
  index+=1
  print("\n\n")  

plt.show()
