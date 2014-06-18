#!/usr/bin/python
import copy
from subprocess import call, Popen
MOTES=[1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008]
TXMOTES=MOTES[:6]
CHANNELMIN=11
CHANNELMAX=26
CHANNELSTEP=3
TRIMMAX=15
TRIMSTEP=3
STARTDELAY=100000
DIFFDELAY=1175
NUMMEASURES=7
MEASUREIDPADDING=10-NUMMEASURES

currenttxindex=[0, 1]
currentchannel=CHANNELMIN
currenttrim=[0, 0]
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
    transmitcmd+=" "+str(currenttx[0])+" "+str(currenttx[1])+" "+str(currentchannel)+" "+str(currenttrim[0])+" "+str(currenttrim[1])+" 0 0 "+str(STARTDELAY+i*DIFFDELAY)+" "+str(measurid)
    measurid+=1
  print("ID: "+ str(measurid-NUMMEASURES)+".."+str(measurid))
  print("TX: " + str(currenttx))
  print("RX: " + str(currentrx))
  measurid+=MEASUREIDPADDING
  #print(transmitcmd)
  #print(receivecmd)
  receivecmd=Popen(receivecmd, shell=True)
  call(transmitcmd, shell=True)
  print("----", end="", flush=True)
  receivecmd.wait()
  print("|----")
  currenttxindex[1]+=1
  if currenttxindex[1] >= len(TXMOTES):
    currenttxindex[0] += 1
    currenttxindex[1] = currenttxindex[0] + 1
    if currenttxindex[0] >= len(TXMOTES)-1:
      currenttxindex[0] = 0
      currenttxindex[1] = 1
      currentchannel+= CHANNELSTEP
      if currentchannel > CHANNELMAX:
        currentchannel = CHANNELMIN
        currenttrim[0]+=TRIMSTEP
        if currenttrim[0] > TRIMMAX:
          exit(0)
      print("=====================================")
      print("Channel: "+str(currentchannel))