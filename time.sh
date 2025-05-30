#!/bin/bash

start=`date +%s`
sleep 5s
end=`date +%s`
time_distance=$(expr $(date +%s -d "2010-03-10 17:36:24") - $(date +%s -d "2010-03-09 13:36:23")) ; 
hour_distance=$(expr ${time_distance} / 3600) ; 
hour_remainder=$(expr ${time_distance} % 3600) ; 
min_distance=$(expr ${hour_remainder} / 60) ; 
min_remainder=$(expr ${hour_remainder} % 60) ; 
echo “time_distance is ${hour_distance} hour ${min_distance} min ${min_remainder} sec”
