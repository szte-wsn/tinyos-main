#!/usr/bin/python2
import sys
import time

#tos stuff
import WaveForm
import SyncMsg
from tinyos.message import *
#plotter
import matplotlib.pyplot as plt
import matplotlib.animation as animation

UPDATE_INTERVAL=100

#extracted settings from InfrastructureSettings.h
SETTINGS="\
      {RSYN,  TX1,  TX1,  TX1,  W10, SSYN,  TX1,  TX1,   RX,  W10, RSYN,   RX,  TX1,   RX,  W10, RSYN,   RX,   RX,   RX,  W10},\
      {RSYN,   RX,   RX,   RX,  W10, RSYN,  TX2,  TX2,  TX1,  W10, SSYN,  TX1,   RX,  TX1,  W10, RSYN,   RX,  TX1,   RX,  W10},\
      {RSYN,  TX2,   RX,   RX,  W10, RSYN,   RX,   RX,   RX,  W10, RSYN,  TX2,  TX2,  TX2,  W10, SSYN,  TX1,   RX,  TX1,  W10},\
      {SSYN,   RX,  TX2,  TX2,  W10, RSYN,   RX,   RX,  TX2,  W10, RSYN,   RX,   RX,   RX,  W10, RSYN,  TX2,  TX2,  TX2,  W10}\
"
#must be a sync slot
CLEARSLOT=0
#the first line of settings represents node with the id of NODEIDSHIFT, the second line represents the node with the id of NODEIDSHIFT+1 and so on
NODEIDSHIFT=1
TX1MOTE="TX1"
TX2MOTE="TX2"
RXMOTE="RX"
SYNCAMTYPE=6
#end of extracted settings

slots=[]
rxCounter=[]

class Wave:
  WAVE_PARTS=7
  REAL_WAVELENGTH=500
  
  def __init__(self, nodeid, waveform):
    self.data=[]
    self.nodeid=nodeid
    self.received=0
    self.waveform=waveform
  
  def addValues(self, values):
    self.received+=1
    self.data.extend(values)
    
  

class Receiver:
  
  def __init__(self, whattodraw, motestring):
    self.mif = MoteIF.MoteIF()
    self.tos_source = self.mif.addSource(motestring)
    self.mif.addListener(self, WaveForm.WaveForm)
    self.mif.addListener(self, SyncMsg.SyncMsg)
    self.drawId=int(whattodraw[1:])
    if whattodraw.startswith('M'):
      self.moteMode=True
    else:
      self.moteMode=False
    
    self.waves=[]
    
    self.fig=plt.figure()
    self.subplots=[]
    if self.moteMode:
      plotcolumns=1
      plotrows=len(rxCounter[self.drawId-NODEIDSHIFT])//plotcolumns
      while plotrows > 3:
        plotcolumns+=1
        plotrows=len(rxCounter[self.drawId-NODEIDSHIFT])//plotcolumns
      
      for i in range(len(rxCounter[self.drawId-NODEIDSHIFT])):
        self.subplots.append(self.fig.add_subplot(plotrows,plotcolumns,i+1))
        self.subplots[i].set_title(rxCounter[self.drawId][i]) # slot Nr would be better
        #this takes too much space
        #self.subplots[i].set_xlabel('time [sample]')
        #self.subplots[i].set_ylabel('RSSI')
    else:
      self.subplots.append(self.fig.add_subplot(1,1,1))
      self.subplots[0].set_title("#"+str(self.drawId)+" TX: "+str(slots[self.drawId][0])+"/"+str(slots[self.drawId][1]))
    
    self.plotDirty=False
    self.ani=animation.FuncAnimation(self.fig, self.plotAnim, interval=UPDATE_INTERVAL)
    plt.tight_layout()
    plt.show()
    
  def clearPlots(self):
    if self.plotDirty:
      self.plotDirty=False
      for i in range(len(self.subplots)):
        self.subplots[i].lines=[]
  
  def plotAnim(self, i):
    if self.moteMode:
      for i in range(len(self.waves)):
        if self.waves[i].received == Wave.WAVE_PARTS and self.waves[i].nodeid == self.drawId:
          self.waves[i].received+=1
          self.clearPlots()
          self.subplots[self.waves[i].waveform].plot(range(Wave.REAL_WAVELENGTH),self.waves[i].data[0:Wave.REAL_WAVELENGTH])
    else:
      for i in range(len(self.waves)):
        if self.waves[i].received == Wave.WAVE_PARTS and rxCounter[self.waves[i].nodeid-NODEIDSHIFT][self.waves[i].waveform] == self.drawId:
          self.waves[i].received+=1
          self.clearPlots()
          self.subplots[0].plot(range(Wave.REAL_WAVELENGTH),self.waves[i].data[0:Wave.REAL_WAVELENGTH], label=str(self.waves[i].nodeid))
          self.subplots[0].legend()

  def receive(self, src, msg):
    if msg.get_amType() == WaveForm.AM_TYPE:
      if msg.get_whichPartOfTheWaveform() == 0: #start message
        newWaveInstance = Wave(msg.getAddr(), msg.get_whichWaveform())
        newWaveInstance.addValues(msg.get_data())
        self.waves.append(newWaveInstance)
      else:
        for i in range(len(self.waves)):
          if self.waves[i].nodeid == msg.getAddr() and self.waves[i].waveform == msg.get_whichWaveform():
            if self.waves[i].received == msg.get_whichPartOfTheWaveform():
              self.waves[i].addValues(msg.get_data())
            break #there should be only one element in the list whith the same nodeid and waveform
    elif msg.get_amType() == SyncMsg.AM_TYPE and msg.get_originalAm() == SYNCAMTYPE and msg.get_frame()-1 == CLEARSLOT: #sync sends the next frame's number
      self.plotDirty=True
      print(len(self.waves))
      self.waves=[]

def main():
  if '-h' in sys.argv or len(sys.argv) < 2:
    print("Usage:", sys.argv[0], "M<moteid>|S<slotid> sf@localhost:9002")
    sys.exit()

  #read the motesettings c array
  settings = ''.join(SETTINGS.split()) #remove whitespaces
  settings=settings[1:-1] #remove the first '{' and last '}'
  settings=settings.split("},{") #split to lines
  for i in range(len(settings)):
    settings[i]=settings[i].split(',')#split to slots
    rxCounter.append([])
  for i in range(len(settings[0])):
    tx1=-1
    tx2=-1
    rxmotes=[]
    rxbuffers=[]
    for j in range(len(settings)):
      if settings[j][i] == TX1MOTE:
        tx1=j+NODEIDSHIFT
      elif settings[j][i] == TX2MOTE:
        tx2=j+NODEIDSHIFT
      elif settings[j][i] == RXMOTE:
        rxmotes.append(j+NODEIDSHIFT)
        rxbuffers.append(len(rxCounter[j]))
        rxCounter[j].append(i)
    slots.append( (tx1, tx2, rxmotes, rxbuffers) )
  if len(sys.argv)==2:
    w = Receiver(sys.argv[1], "sf@localhost:9002" )
  else:
    w = Receiver(sys.argv[1], sys.argv[2] )

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass