#!/usr/bin/python
import copy
from subprocess import call
MOTES=[1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008]
TXMOTES=MOTES[:6]
CHANNELMIN=11
CHANNELMAX=26
TXLEN=1000
STARTDELAY=100000
TXDELAY=16
DIFFDELAY=100000
NUMMEASURES=4
MEASUREIDPADDING=10-NUMMEASURES

currenttxindex=[0, 1]
currentchannel=CHANNELMIN
measurid = 0
while True:
  currenttx = [TXMOTES[currenttxindex[0]], TXMOTES[currenttxindex[1]]]
  currentrx = copy.copy(MOTES)
  currentrx.remove(currenttx[0])
  currentrx.remove(currenttx[1])
  receivecmd="java BaseStationApp -comm sf@localhost:9002"
  for m in currentrx:
    receivecmd+=" " + str(m)
  transmitcmd="java Send"
  for i in range(NUMMEASURES):
    transmitcmd+=" "+str(currenttx[0])+" "+str(currenttx[1])+" "+str(currentchannel)+" 0 0 0 0 "+str(STARTDELAY+i*DIFFDELAY)+" "+str(measurid)
    measurid+=1
  print("ID: "+ str(measurid-NUMMEASURES)+".."+str(measurid))
  print("TX: " + str(currenttx))
  print("RX: " + str(currentrx))
  measurid+=MEASUREIDPADDING
  #print(transmitcmd)
  #print(receivecmd)
  call(transmitcmd, shell=True)
  call(receivecmd, shell=True)
  print("--------")
  currenttxindex[1]+=1
  if currenttxindex[1] >= len(TXMOTES):
    currenttxindex[0] += 1
    currenttxindex[1] = currenttxindex[0] + 1
    if currenttxindex[0] >= len(TXMOTES)-1:
      currenttxindex[0] = 0
      currenttxindex[1] = 1
      currentchannel+=1
      if currentchannel > CHANNELMAX:
        currentchannel = CHANNELMIN
        print("Measure done on all channel")
        exit(0)
      print("=====================================")
      print("Channel: "+str(currentchannel))
