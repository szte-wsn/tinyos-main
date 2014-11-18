#!/usr/bin/python

import threading
import serial
import matplotlib.pyplot as plt
import matplotlib.animation as animation

def readSerial():
  while True:
    newval = ord(ser.read())
    yar.append(newval)
    xar.append(xar[-1]+1)
    yar.pop(0)
    xar.pop(0)

def plotAnim(i):
  ax1.clear()
  ax1.plot(xar, yar)

ser = serial.Serial('/dev/ttyUSB1', 1000000, timeout=1)

fig=plt.figure()
ax1 = fig.add_subplot(1,1,1)
xar = list(range(10000))
yar = [0]*10000

t = threading.Thread(target=readSerial)
t.daemon = True
t.start()

ani = animation.FuncAnimation(fig, plotAnim, interval=0.002)
plt.show()
