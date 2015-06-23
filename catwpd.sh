#!/bin/bash
MAPCONFIG=/home/NWP/RIXINWRF/wrfout/mapping.config
CONFIG=/home/NWP/RIXINWRF/source/file.down
SIZE=`cat $MAPCONFIG | grep size | awk -F'= ' '{print $2}'`
TXTNAME=`cat $MAPCONFIG | grep txtname | awk -F'= ' '{print $2}'`
LAT=`cat $MAPCONFIG | grep clat | awk -F'= ' '{print $2}'`
LON=`cat $MAPCONFIG | grep clon | awk -F'= ' '{print $2}'`
HIGH=`cat $MAPCONFIG | grep high | awk -F'= ' '{print $2}'`
TIME=`cat $CONFIG | grep "f_file" |awk -F'= ' '{print$2}' | sed 's/ //g'`
#TIME=2013050712
s=$(($SIZE+2))
for i in $(seq 3 $s)
do
	fname=`echo $TXTNAME | awk -F',' -v fly=$i '{print $fly}'`
	lat=`echo $LAT | awk -F',' -v fly=$i '{print $fly}'`
	lon=`echo $LON | awk -F',' -v fly=$i '{print $fly}'`
	high=`echo $HIGH | awk -F',' -v fly=$i '{print $fly}'`
	cat $fname$TIME.txt | grep "$lat" | grep "$lon" | grep " $high " > $fname$TIME.WPD
done
