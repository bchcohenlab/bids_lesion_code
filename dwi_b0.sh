#!/bin/bash

# Simple script to make a b0 and b1000 map with BIDS-compliant name

dwi=$1
participant=`basename $dwi | cut -d _ -f 1`

fslroi $dwi ${participant}_desc-b0_dwi.nii.gz 0 1

((last_frame=`fslval $dwi dim4` - 1))
fslroi $dwi ${participant}_desc-b1000_dwi.nii.gz ${last_frame} 1
