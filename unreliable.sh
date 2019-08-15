#!/bin/bash
###########################################
# @Author: Sriharsha Gangam
# email: Sriharsha_Gangam@comcast.com
###########################################

echo "Usage: unreliable.sh <successProb> <jobDurationSec> <runDay>"
if [ $# -lt 3 ]; 
  then echo "Illegal number of parameters"
  exit 1
fi
echo Running $0 $@
SUCCESS_PROB=$1
DURATION=$2
RUN_DAY=$3
RAND=$(bc -l <<< "scale=4 ; ${RANDOM}/32767")
sleep $DURATION
if [ $(echo " $RAND < $SUCCESS_PROB" | bc) -eq 1 ]; then
    echo "Random value: $RAND. Job Success"
    exit 0
fi
echo "Random value: $RAND. Job Failed."
exit 1
