#!/usr/bin/python
import sys
DEBUGSYNC = 3
SSYNCSLOT = "SSYN"
RSYNCSLOT = "RSYN"
TX1SLOT = "TX1"
TX2SLOT = "TX2"
RXSLOT = "RX"

DSYNCSLOT ="DSYN"
DEBSLOT="DEB"
NDEBSLOT="NDEB"


motes=int(sys.argv[1])
numRX=(motes-1)*(motes-2)
if sys.argv[2] == 'y':
  generateDuplicates=True
else:
  generateDuplicates=False
if sys.argv[3] == 'y':
  sendWaveform=True
else:
  sendWaveform=False
if len(sys.argv) < 5:
  waitSlot = ""
else:
  waitSlot = sys.argv[4]

activeslots=[]
for i in range(0, motes):
  for j in range(i+1 if generateDuplicates else 0 , motes):
    if i != j:
      activeslots.append([i,j])
if generateDuplicates:
  activeslots.extend(activeslots)
nonDebugSlots = len(activeslots)
nonDebugSlots += motes #sync slots



superframe=[]
txmotes = []
done=False
index = 0
nextSync = 0
if(sendWaveform):
  debugNode = 0
  debugIndex = 0
else:
  debugNode = motes
#we don't count the wait slots: we calculate it as part of the sync slot
while not done:
  slot = []
  if index < nonDebugSlots:
    if index % motes == 0: #sync slot
      for i in range(0,nextSync):
        slot.append(RSYNCSLOT)
      slot.append(SSYNCSLOT)
      for i in range(nextSync+1,motes):
        slot.append(RSYNCSLOT)
      nextSync+=1
      nextSync%=motes
      superframe.append(slot)
      if waitSlot != "":
        slot = []
        for i in range(motes):
          slot.append(waitSlot)
        superframe.append(slot)
      txmotes = list(range(motes))
      txmotes.remove(nextSync)
    else:
      for activeslot in activeslots:
        if(activeslot[0] == nextSync and txmotes.count(activeslot[1]) >0 ):
          activeslots.remove(activeslot)
          txmotes.remove(activeslot[1])
          break
        elif(activeslot[1] == nextSync and txmotes.count(activeslot[0]) >0 ):
          activeslots.remove(activeslot)
          txmotes.remove(activeslot[0])
          break
      for i in range(motes):
        if activeslot.count(i) == 0:
          slot.append(RXSLOT)
        elif( activeslot[0] == i):
          slot.append(TX1SLOT)
        else:
          slot.append(TX2SLOT)
      superframe.append(slot)
    index+=1
  elif debugNode < motes:
    if (index-nonDebugSlots) % DEBUGSYNC == 0: #sync slot
      for i in range(0,nextSync):
        slot.append(RSYNCSLOT)
      slot.append(DSYNCSLOT)
      for i in range(nextSync+1,motes):
        slot.append(RSYNCSLOT)
      nextSync+=1
      nextSync%=motes
      superframe.append(slot)
    else:
      for i in range(0,debugNode):
        slot.append(NDEBSLOT)
      slot.append(DEBSLOT)
      for i in range(debugNode+1, motes):
        slot.append(NDEBSLOT)
      debugIndex+=1
      if debugIndex == numRX:
        debugNode+=1
        debugIndex=0
      superframe.append(slot)
    index+=1
  else:
    done = True

print("#define  NUMBER_OF_INFRAST_NODES "+str(motes))
print("#define NUMBER_OF_SLOTS "+str(len(superframe)))
print("#define NUMBER_OF_RX "+str(numRX))
print("{")
print("//\t", end="")
for i in range(len(superframe)):
    print("%5s "%i, end="")
print()
for i in range(motes):
  print("\t{ ", end="")
  for j in range(len(superframe)):
    print("%5s"%superframe[j][i], end="")
    if j < len(superframe)-1:
      print(",", end="")
  print("},")
print("}")