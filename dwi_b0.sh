#!/bin/bash

# Simple script to make a b0 and b1000 map with BIDS-compliant name

dwi=$1
participant=`basename $dwi | cut -d _ -f 1`
dwi_name=`echo $dwi| cut -d '.' -f1`
bval=${dwi_name}.bval

fslroi $dwi ${participant}_desc-b0_dwi.nii.gz 0 1

#((last_frame=`fslval $dwi dim4` - 1))

b1000_frame=0
for i in `cat $bval`; do
    if [ $i == 1000 ]; then
        break
    else
        ((b1000_frame++))
    fi
done

fslroi $dwi ${participant}_desc-b1000_dwi.nii.gz ${b1000_frame} 1
