#!/bin/bash

# This code generates the mapping from the B0 image to the T1W, and applies this mapping to the ADC map as well
# USAGE: ../../code/ants_dwi_to_T1w.sh . sub-0195

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12  # controls multi-threading
export ANTSPATH=/programs/x86_64-linux/ants/2.3.1/bin/ # path to ANTs binaries

echo This will use ${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS} threads at a time
echo Using the ANTs version installed at ${ANTSPATH}

# temp_dir=./ants_Temp
# mkdir -p $temp_dir

working_dir=$1
participant=$2

template=${working_dir}/${participant}_T1w.nii.gz # This is the T1w
mask=${working_dir}/${participant}_space-T1w_desc-brain_mask.nii.gz # This is the mask made from the T1w in prior steps
orig=${working_dir}/${participant}_desc-b0_dwi.nii.gz # This is the b0 image
b1000=${working_dir}/${participant}_desc-b1000_dwi.nii.gz # This is the b1000 image
adc=${working_dir}/${participant}_desc-adc_dwi.nii.gz # This is the adc image

T1w=`basename ${template}`

# Generate linear and warp from b0 space to T1 target
# -x $mask \
antsRegistrationSyNQuick.sh \
	-d 3 \
	-m $orig \
	-f $T1w \
	-t br \
	-o ${participant}_space-T1w_desc-b0_dwi

# remove non-BIDS suffix
mv ${participant}_space-T1w_desc-b0_dwiWarped.nii.gz ${participant}_space-T1w_desc-b0_dwi.nii.gz


# Then we apply the transform to bring the adc into T1w space:
antsApplyTransforms \
	-d 3 \
	-i ${adc} \
	-r ${T1w} \
	-t warps/${participant}_space-T1w_desc-b0_dwi1Warp.nii.gz \
	-t warps/${participant}_space-T1w_desc-b0_dwi0GenericAffine.mat \
	-n BSpline \
	-o ${participant}_space-T1w_desc-adc_dwi.nii.gz

# and the b1000 map too:
antsApplyTransforms \
	-d 3 \
	-i ${b1000} \
	-r ${T1w} \
	-t warps/${participant}_space-T1w_desc-b0_dwi1Warp.nii.gz \
	-t warps/${participant}_space-T1w_desc-b0_dwi0GenericAffine.mat \
	-n BSpline \
	-o ${participant}_space-T1w_desc-b1000_dwi.nii.gz

# Clean up
rm *mat
rm *Warp.nii.gz
