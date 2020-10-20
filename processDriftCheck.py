# this does fourier transforma analysis on dffmovies from drifitng
# checkerboard visual stumulation to find power, elevation, and azimuth maps
# final output -
# elPowerMap
# aziPowerMap
# elevationMap
# azimuthMap

import os
from scipy.io import loadmat
from scipy import fftpack
import numpy as np
import matplotlib.pyplot as plt

# import data parameters
d = 'dffMovies_8311_s4r1.mat'
curr_folder = os.path.dirname(os.path.realpath(__file__))
data_folder = os.path.join(curr_folder,'data')
os.chdir(curr_folder)
data = loadmat(os.path.join(data_folder,d))

# define variables
downUp = data['downUp']
topDown = data['topDown']
leftRight = data['leftRight']
rightLeft = data['rightLeft']

downUp = downUp[20:,:,:]
topDown = topDown[20:,:,:]
leftRight = leftRight[20:,:,:]
rightLeft = rightLeft[20:,:,:]

downUpPosVec = data['DUPositionAvg']
topDownPosVec = data['TDPositionAvg']
leftRightPosVec = data['LRPositionAvg']
rightLeftPosVec = data['RLPositionAvg']

horizontalTimeSteps = data['horizontalTimeSteps']
verticalTimeSteps = data['verticalTimeSteps']

##################################################
# AZIMUTH MAP
# azimuth map creation  (vertical bars, rightLeft, leftRight)

RLspectrumMovie = np.fft.fft(rightLeft, axis=0)

#generate power movie
RLpowerMovie = (np.abs(RLspectrumMovie) *2.) / np.size(RLspectrumMovie,0)
RLpowerMap = np.abs(RLpowerMovie[1,:,:])

#generate phase movie
RLphaseMovie = np.angle(RLspectrumMovie)
RLphaseMap = -1*RLphaseMovie[1,:,:]
RLphaseMap = RLphaseMap % (2 * np.pi)

#frequency
RLfreqArray = fftpack.fftfreq(np.size(RLspectrumMovie,0), d = .1)
RLfreq = RLfreqArray[1]


#calculate time delay
RLtimeShiftMap = RLphaseMap / (2*np.pi) / RLfreq

########################################################
LRspectrumMovie = np.fft.fft(leftRight, axis=0)

#generate power movie
LRpowerMovie = (np.abs(LRspectrumMovie) *2.) / np.size(LRspectrumMovie,0)
LRpowerMap = np.abs(LRpowerMovie[1,:,:])


#generate phase movie
LRphaseMovie = np.angle(LRspectrumMovie)
LRphaseMap = -1*LRphaseMovie[1,:,:]
LRphaseMap = LRphaseMap % (2 * np.pi)

#frequency
LRfreqArray = fftpack.fftfreq(np.size(LRspectrumMovie,0),d = .1)
LRfreq = LRfreqArray[1]


#calculate time delay
LRtimeShiftMap = LRphaseMap / (2*np.pi) / LRfreq

# convert time delay to angular position
verticalTimeSteps = np.round(verticalTimeSteps, 1)

# leftRight
LRradianMap = LRtimeShiftMap.copy()
for ix, iy in np.ndindex(LRradianMap.shape):
    timeShift = np.round(LRradianMap[ix, iy], 1)
    if timeShift > 9.3:
        timeShift = 9.3
    elif timeShift == 0:
        timeShift = 0.1

    timeIndex = np.where(verticalTimeSteps == timeShift)
    LRradianMap[ix, iy] = leftRightPosVec[0, timeIndex[1][0]]

# rightleft
RLradianMap = RLtimeShiftMap.copy()
for ix, iy in np.ndindex(RLradianMap.shape):
    timeShift = np.round(RLradianMap[ix, iy], 1)
    if timeShift > 9.3:
        timeShift = 9.3
    elif timeShift == 0:
        timeShift = 0.1

    timeIndex = np.where(verticalTimeSteps == timeShift)
    RLradianMap[ix, iy] = rightLeftPosVec[0, timeIndex[1][0]]

# average together to get azimuthmap
azimuthMap = np.stack((LRradianMap, RLradianMap), axis=-1)
azimuthMap = np.mean(azimuthMap, axis=2)

aziPowerMap = np.stack((LRpowerMap, RLpowerMap),axis = -1)
aziPowerMap = np.mean(aziPowerMap,axis = 2)

###########################################################
# ELEVATION MAPS
# elevation map creation  horizontal bars, topdown, downUp

DUspectrumMovie = np.fft.fft(downUp, axis=0)

#generate power movie
DUpowerMovie = (np.abs(DUspectrumMovie) *2.) / np.size(DUspectrumMovie,0)
DUpowerMap = np.abs(DUpowerMovie[1,:,:])

#generate phase movie
DUphaseMovie = np.angle(DUspectrumMovie)
DUphaseMap = -1*DUphaseMovie[1,:,:]
DUphaseMap = DUphaseMap % (2 * np.pi)

#frequency
DUfreqArray = fftpack.fftfreq(np.size(DUspectrumMovie,0), d = .1)
DUfreq = DUfreqArray[1]


#calculate time delay
DUtimeShiftMap = DUphaseMap / (2*np.pi) / DUfreq

########################################################
TDspectrumMovie = np.fft.fft(topDown, axis=0)

#generate power movie
TDpowerMovie = (np.abs(TDspectrumMovie) *2.) / np.size(TDspectrumMovie,0)
TDpowerMap = np.abs(TDpowerMovie[1,:,:])


#generate phase movie
TDphaseMovie = np.angle(TDspectrumMovie)
TDphaseMap = -1*TDphaseMovie[1,:,:]
TDphaseMap = TDphaseMap % (2 * np.pi)

#frequency
TDfreqArray = fftpack.fftfreq(np.size(TDspectrumMovie,0),d = .1)
TDfreq = TDfreqArray[1]


#calculate time delay
TDtimeShiftMap = TDphaseMap / (2*np.pi) / TDfreq

# convert time delay to angular position
horizontalTimeSteps = np.round(horizontalTimeSteps, 1)

# downUp
DUradianMap = DUtimeShiftMap.copy()
for ix, iy in np.ndindex(DUradianMap.shape):
    timeShift = np.round(DUradianMap[ix, iy], 1)
    if timeShift > 8.6:
        timeShift = 8.6
    elif timeShift == 0:
        timeShift = 0.1

    timeIndex = np.where(horizontalTimeSteps == timeShift)
    DUradianMap[ix, iy] = downUpPosVec[0, timeIndex[1][0]]

# topdown
TDradianMap = TDtimeShiftMap.copy()
for ix, iy in np.ndindex(TDradianMap.shape):
    timeShift = np.round(TDradianMap[ix, iy], 1)
    if timeShift > 8.6:
        timeShift = 8.6
    elif timeShift == 0:
        timeShift = 0.1

    timeIndex = np.where(horizontalTimeSteps == timeShift)
    TDradianMap[ix, iy] = topDownPosVec[0, timeIndex[1][0]]

# average together to get elevation
elevationMap = np.stack((DUradianMap, TDradianMap), axis=-1)
elevationMap = np.mean(elevationMap, axis=2)

elPowerMap = np.stack((DUpowerMap, TDpowerMap),axis = -1)
elPowerMap = np.mean(elPowerMap,axis = 2)

elevationMap = elevationMap * (180 / np.pi)
azimuthMap = (azimuthMap * (180 / np.pi)) + np.min(azimuthMap)
