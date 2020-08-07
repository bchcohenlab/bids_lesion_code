#!/bin/bash

# This code generates the mapping from the B0 image to the T1W, and applies this mapping to the ADC map as well
# USAGE: ../../code/ants_dwi_to_T1w.sh ../anat/sub-0195_T1w.nii.gz sub-0195_desc-b0_dwi.nii.gz

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12  # controls multi-threading
export ANTSPATH=/programs/x86_64-linux/ants/2.3.1/bin/ # path to ANTs binaries

echo This will use ${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS} threads at a time
echo Using the ANTs version installed at ${ANTSPATH}

# temp_dir=./ants_Temp
# mkdir -p $temp_dir

working_dir=$1
participant=$2
tag=$3

template=${working_dir}/${participant}_T1w.nii.gz # This is the T1w
mask=${working_dir}/${participant}_space-T1w_desc-brain_mask.nii.gz # This is the mask made from the T1w in prior steps
orig=${working_dir}/${participant}_${tag}.nii.gz # This is the input image

T1w=`basename ${template}`

# Generate linear and warp from input space to T1 target
# -x $mask \
antsRegistrationSyNQuick.sh \
	-d 3 \
	-m $orig \
	-f $T1w \
	-t br \
	-o ${participant}_space-T1w_${tag}

# remove non-BIDS suffix
mv ${participant}_space-T1w_${tag}Warped.nii.gz ${participant}_space-T1w_${tag}.nii.gz

# Clean up
rm *mat
rm *Warp.nii.gz