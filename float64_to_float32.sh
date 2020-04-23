#!/bin/bash



for i in `find . -type f -name "*.gz"`; do 
	if grep -q FLOAT <<< `fslinfo $i | grep FLOAT64`; then
		echo converting $i to float32
		fslmaths $i $i -odt float
	fi
done