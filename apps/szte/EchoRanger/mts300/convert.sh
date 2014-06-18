#!/bin/sh
java org.szte.wsn.dataprocess.Transfer -i binfile -o textfile -ns -ms -om  rewrite -if $1.bin
java org.szte.wsn.echoranger.Transpose ";" $1waveform.csv > $1_wft.csv
