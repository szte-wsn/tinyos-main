import numpy
import scipy.optimize as opt
from numpy import cos
import sys

unknownSign = 6000; #what is the unknown coordinate sign
fileName = "RMMeasuredDistances.txt"
enableStdout = False;
printPartialResult = False;
numpy.set_printoptions(linewidth=200)
numpy.set_printoptions(suppress=True)
numpy.set_printoptions(precision=3)

def goodnessFunction(unknownCoordinates, originalCoordinatesArray, d):
  if enableStdout == True:
    print 'unknownCoordinates: '
    print unknownCoordinates
  tmpCoordinate = numpy.zeros(shape=(len(originalCoordinatesArray), len(originalCoordinatesArray[0])))
  k = 0;
  for j in range(0,len(originalCoordinatesArray[0])):
    for i in range(0,len(originalCoordinatesArray)):
		  #print 'i: %d, j: %d' % (i,j)
      if originalCoordinatesArray[i][j] == unknownSign:
        tmpCoordinate[i][j] = unknownCoordinates[k];
        k = k + 1;
      else:
        tmpCoordinate[i][j] = originalCoordinatesArray[i][j]
  if enableStdout == True:
    print 'tmpCoordinate'
    print tmpCoordinate
  #create matrices 
  M1 = numpy.zeros(shape=(4,len(distances[0]))) 
  M2 = numpy.zeros(shape=(4,len(distances[0])))
  M1[0] = distances[0]
  M2[0] = distances[1]
  for i in range (0,len(tmpCoordinate[0])):
    indexM1 = numpy.where(M1[0] == tmpCoordinate[0][i])  
    for index in indexM1:
      for j in range (1,4):
        M1[j][index] = tmpCoordinate[j][i]
    indexM2 = numpy.where(M2[0] == tmpCoordinate[0][i])
    for index in indexM2:
      for j in range (1,4):
        M2[j][index] = tmpCoordinate[j][i]
  if enableStdout == True:
    print 'distances'
    print distances
    print 'd'
    print d
    print 'M1'
    print M1
    print 'M2'
    print M2
  F = numpy.zeros(shape=(len(M1[0])))  #how many equalition have  
  for i in range(0,len(M1[0])):
    if enableStdout == True:
      print "(%4.4f - %4.4f) + (%4.4f - %4.4f) + (%4.4f - %4.4f) - %4.4f = %4.4f - %4.4f" % (M1[1][i], M2[1][i], M1[2][i], M2[2][i], M1[3][i], M2[3][i], d[i], ((M1[1][i] - M2[1][i])**2 + (M1[2][i] - M2[2][i])**2 + (M1[3][i] - M2[3][i])**2), d[i]**2)
#     print "(%4.4f - %4.4f) + (%4.4f - %4.4f) + (%4.4f - %4.4f) - %4.4f = %4.4f + %4.4f + %4.4f - %4.4f = %4.4f - %4.4f = %4.4f" % (M1[1][i], M2[1][i], M1[2][i], M2[2][i], M1[3][i], M2[3][i], d[i], (M1[1][i] - M2[1][i])**2, (M1[2][i] - M2[2][i])**2, (M1[3][i] - M2[3][i])**2, d[i]**2,((M1[1][i] - M2[1][i])**2 + (M1[2][i] - M2[2][i])**2 + (M1[3][i] - M2[3][i])**2), d[i]**2, ((M1[1][i] - M2[1][i])**2 + (M1[2][i] - M2[2][i])**2 + (M1[3][i] - M2[3][i])**2 - d[i]**2))
    s = (M1[1][i] - M2[1][i])**2 + (M1[2][i] - M2[2][i])**2 + (M1[3][i] - M2[3][i])**2 - d[i]**2;
    F[i] = abs(s); 
    #F = F + abs(s); # for minimize
    #F = F + s; # for minimize
    if enableStdout == True:
      print 's: %4.4f' % s
      print 'F: %4.4f' % F[i]
  if enableStdout == True:
    print 'F'
    print F
    print 'goodness: ', 
    print sum(F.tolist())
  #return sum(F.tolist())
  if enableStdout == True:
    print numpy.dot(numpy.matrix.transpose(F), F)
  return numpy.dot(numpy.matrix.transpose(F), F)

f = open(fileName, "r")
#read mote ids
moteIDs = []
line = f.readline()
words = line.split()
for word in words:
  moteIDs.append(int(word));
  #print word
    
coordinateSize = len(moteIDs)

#read fix coordinates
unknownSize = 0
j = 0;
coordinate = numpy.zeros(shape=(4,coordinateSize))
for i in range (0,coordinateSize):
  line = f.readline()
  words = line.split()
  #print words
  for word in words:
    coordinate[j][i] = (float(word));
    if coordinate[j][i] == unknownSign:
    	unknownSize = unknownSize + 1;
    j = j+1
  j = 0
if enableStdout == True:
  print 'coordinate'
  print coordinate
  
#read distances beetween known and unknown motes
i = 0
j = 0
datas = f.readlines()
distances = numpy.zeros(shape=(3,len(datas)))
for line in datas:
  i = 0
  words = line.split()
  for word in words:
    distances[i][j] = float(word)
    i = i + 1
  j = j + 1
print 'moteIDs'  
print moteIDs
if enableStdout == True:
  print 'coordinateSize'  
  print coordinateSize  
print 'coordinate'
print coordinate
print 'distances'
print distances
if enableStdout == True:
  print 'distanceLength'
  print len(distances[0])
  print 'unknownSize'
  print unknownSize

unknownCoordinates = numpy.zeros(shape=(unknownSize))

#modify the original input matrix, with replace unknown coordinates with 0
tmpCoordinate = numpy.zeros(shape=(len(coordinate), len(coordinate[0])))
if enableStdout == True:
  print 'beforeCoordinate'
  print tmpCoordinate
k = 0;
for i in range(0,len(coordinate)):
  for j in range(0,len(coordinate[0])):
		#print 'i: %d, j: %d' % (i,j)
    if coordinate[i][j] == unknownSign:
      if enableStdout == True:
        print tmpCoordinate[i][j],
        print unknownCoordinates[k]
      tmpCoordinate[i][j] = unknownCoordinates[k];
      k = k + 1;
    else:
      tmpCoordinate[i][j] = coordinate[i][j]
if enableStdout == True:
  print 'replaces matrix'
  print tmpCoordinate
  print 'coordinate'
  print coordinate
  print 'coordSize'
  print coordinateSize
  print len(coordinate)
 
firstArray = numpy.zeros(shape=(4,len(distances[0]))) 
#create matrices
secondArray = numpy.zeros(shape=(4,len(distances[0])))
firstArray[0] = distances[0]
secondArray[0] = distances[1]
for i in range (0,coordinateSize):
  indexFirstArray = numpy.where(firstArray[0] == coordinate[0][i])  
  for index in indexFirstArray:
    for j in range (1,4):
      firstArray[j][index] = tmpCoordinate[j][i]
  indexSecondArray = numpy.where(secondArray[0] == coordinate[0][i])
  for index in indexSecondArray:
    for j in range (1,4):
      secondArray[j][index] = tmpCoordinate[j][i]

start = unknownCoordinates
start[0] = 0
start[1] = 0
start[2] = 0
#start = (1000, 1000, 1000, 1000, 1000)
#print start
#start = (9,91)
if enableStdout == True:
  print 'firstArray'
  print firstArray
  print 'secondArray'
  print secondArray
  print 'distance'
  print distances
  print 'start'
  print start
  print 'coordinateSize'
  print coordinateSize
  print 'coordinateLegth'
  print len(coordinate)
  print 'parameterek:'
  print 'start'
  print start
  print 'coordinate'
  print coordinate
  print 'distances'
  print distances[2]
  print 'metodus'
bnds = list()
for i in range (0,len(unknownCoordinates)):
  bnds.append((0, None))
if enableStdout == True:
  print bnds
#methods: 'Nelder-Mead' 'Powell' 'CG' 'BFGS' - no bounds
#'L-BFGS-B' 'TNC' - only x >= 0
#'COBYLA' 'SLSQP' - any bounds, equality and inequality-based constraints

#run, while found good result
#5000 = 50m is the maximum possible value
#ignore the negative positions
maxValueInCm = 5000
changeValueInCm = 100
goodnessThresholdValue = 5000000000 #if the goodnessFunction above this value, then stop
ResultXValue = numpy.zeros(shape=(unknownSize)) #If the result x value is the same in few iteration (for example above 3), then change this x's start value, to this value
cntResultXValue = numpy.zeros(shape=(unknownSize))
end = 1
while end == 1:
  end = 0;
  result = opt.minimize(goodnessFunction, start, args=(coordinate, distances[2]), method="Powell", bounds=bnds, options={'maxiter':300})
  x = result.x
  for j in range(0,len(x)):
    #if one value is negative, then change this value
    if x[j] < 0:
      if enableStdout == True:
        print 'x: ',
        print x[j]
      end = 1
      start[j] += changeValueInCm
    if start[j] > maxValueInCm:
      end = 2
    else:
      if abs(x[j] - ResultXValue[j]) < 4:
        cntResultXValue[j] += 1
      else:
        cntResultXValue[j] = 0
        ResultXValue[j] = x[j]
      if cntResultXValue[j] > 3 and cntResultXValue[j] < 20:
        start[j] = ResultXValue[j]
      if cntResultXValue[j] >= 20:
        cntResultXValue[j] = 3
        start[j] += 1000
  if enableStdout == True:
    print 'resultXValue and cntResultXValue'
    print ResultXValue
    print cntResultXValue
  if enableStdout == True:
    print end
  if (result.fun > goodnessThresholdValue or end == 1) and end != 2:
    end = 1
  else:
    end = 0
  if enableStdout == True:
    print end
  if printPartialResult == True:
    print 'new start coordinates'
    print start
    print 'result'
    print result
  #sys.stdin.read(1)
 
#other algorithms  
#brute force algorithm
#result = opt.brute(goodnessFunction, ((0,5000), (0,5000), (0,5000), (0,5000)), args=(coordinate, distances[2]))
#simulated annealing
#result = opt.anneal(goodnessFunction, start, args=(coordinate, distances[2]), maxiter=100, lower=(0, 0, 0), dwell=100, disp=True, Tf=1000, schedule='fast')
#minimize
#result = opt.minimize(goodnessFunction, start, args=(coordinate, distances[2]), method="BFGS", bounds=bnds, options={'maxiter':1000, 'disp': True})
#print 'result'
#print result

print 'found x coordinates'
print result.x
  
f.close()
