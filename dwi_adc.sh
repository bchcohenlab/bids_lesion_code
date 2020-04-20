#!/bin/bash

# Simple script to make ADC map with BIDS-compliant name

dwi=$1
participant=`basename $dwi | cut -d _ -f 1`

dwi_bval=`dirname $dwi`/`basename $dwi .nii.gz`.bval

# Get last frame of the dwi, usually 1000
fslsplit ${participant}_dwi.nii.gz ${participant}_dwi_b
first_b=`ls ${participant}_dwi_b* | head -1`
final_b=`ls ${participant}_dwi_b* | tail -1`

if [ -f "$dwi_bval" ]; then
	bval=`awk '{print $NF}' $dwi_bval`
else
	bval=1000
fi

# calculate ADC map
fslmaths ${first_b} -div ${final_b} -log -div $bval ${participant}_desc-adc_dwi

# save a copy of the b-highest map and clean up
mv $final_b ${participant}_desc-b${bval}_dwi.nii.gz
rm ${participant}_dwi_b*