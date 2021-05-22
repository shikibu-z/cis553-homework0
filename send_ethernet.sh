#!/bin/bash

if [ "$#" -lt 1 ]; then
	echo "Usage: ./send_ethernet.sh <dst_mac>"
	exit 1
fi

INTERFACE=`ifconfig | grep eth0 | sed 's/ .*//'`
arping -i ${INTERFACE} -t $1 0.0.0.0 | sed 's/Timeout/Sent message/'

