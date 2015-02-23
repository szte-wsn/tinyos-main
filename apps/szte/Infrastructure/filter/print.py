#!/usr/bin/env python
from datetime import datetime
import struct
import sys
import os
LENGTHFREQ=62500

if len(sys.argv) < 2: #no argument was given, use the newest file
  allfilenames = []
  for f in os.listdir('.'):
    if os.path.isfile(f) and os.path.basename(f).endswith(".raw"):
      allfilenames.append(f)
  filenames = [max(allfilenames)]
else:
  filenames = sys.argv[1:]

for filename in filenames:
  f = open(filename, 'rb')

  #reading the main data
  arraylength = struct.unpack('>I', f.read(4))[0]
  values = struct.unpack('>'+str(arraylength)+'s',f.read(arraylength))[0]
  f.close()

  #print data
  print filename + ":", arraylength, map(ord, values)
