#!/bin/bash

# This code combines two T1w images that are at different resolutions (either with niftymic or fslmaths)
# USAGE: combine_clinical_ax_cor_T1w.sh /Users/alex/BWH_Social_Lesions/Dhand_bids/derivatives/lesions/temp sub-0194 ax sag

# export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12  # controls multi-threading
# export ANTSPATH=/Users/alex/repos/opt/bin/ # path to ANTs binaries

# echo This will use ${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS} threads at a time
# echo Using the ANTs version installed at ${ANTSPATH}

# temp_dir=./ants_Temp
# mkdir -p $temp_dir

working_dir=$1
participant=$2
target_T1w_acq=$3
other_T1w_acq=$4

template=${working_dir}/${participant}_acq-${target_T1w_acq}_T1w.nii.gz # This is the target T1w
orig=${working_dir}/${participant}_acq-${other_T1w_acq}_T1w.nii.gz # This is another T1w

#### High quality fusion using niftymic:

# First, Make binary masks of where the two images have values:
fslmaths \
	${template} \
	-abs \
	-bin \
	temp_${target_T1w_acq}_mask

fslmaths \
	${orig} \
	-abs \
	-bin \
	temp_${other_T1w_acq}_mask


singularity exec \
	-B ${working_dir}:/app/data \
        -B ${BIDSPATH}:${BIDSPATH} \
	${BIDSPATH}/niftymic.sif \
	niftymic_reconstruct_volume \
		--filenames \
			/app/data/${participant}_acq-${target_T1w_acq}_T1w.nii.gz \
			/app/data/${participant}_acq-${other_T1w_acq}_T1w.nii.gz \
		--filenames-masks \
			/app/data/temp_${target_T1w_acq}_mask.nii.gz \
			/app/data/temp_${other_T1w_acq}_mask.nii.gz \
		--output \
			/app/data/${participant}_T1w.nii.gz

# Clean up:
rm -rf \
	config* \
	motion_correction temp* \
	${participant}_T1w_mask.nii.gz



#### Manual process if you don't want to use niftymic:

	# transform_type=a # typically r=rigid or a=rigid+affine work fine since it is the same subject/same modality

	# # Make an isovolumetric version of the target T1w
	# # min_pixelwidth=`fslinfo ${template} | grep pixdim[1-3] | awk '{ print $2 }' | sort -n | head -1`
	# min_pixelwidth=1
	# iso.sh ${template} ${min_pixelwidth}

	# # Generate linear transform from other T1w to taget T1w
	# antsRegistrationSyNQuick.sh \
	# 	-d 3 \
	# 	-m $orig \
	# 	-f ${working_dir}/${participant}_acq-${target_T1w_acq}_T1w_${min_pixelwidth}mm.nii.gz \
	# 	-t ${transform_type} \
	# 	-j 1 \
	# 	-o ${participant}_${other_T1w_acq}_to_${target_T1w_acq}_${transform_type}_T1w_

	# # Make binary masks of where the two images have values:
	# fslmaths \
	# 	${participant}_acq-${target_T1w_acq}_T1w_${min_pixelwidth}mm \
	# 	-abs \
	# 	-bin \
	# 	temp_${target_T1w_acq}_mask

	# fslmaths \
	# 	${participant}_${other_T1w_acq}_to_${target_T1w_acq}_${transform_type}_T1w_Warped \
	# 	-abs \
	# 	-bin \
	# 	temp_${other_T1w_acq}_mask

	# # combine the masks to make a denominator image for division below:
	# fslmaths \
	# 	temp_${target_T1w_acq}_mask \
	# 	-add temp_${other_T1w_acq}_mask \
	# 	temp_denominator

	# # combine the two maps:
	# fslmaths \
	# 	${participant}_acq-${target_T1w_acq}_T1w_${min_pixelwidth}mm \
	# 	-add ${participant}_${other_T1w_acq}_to_${target_T1w_acq}_${transform_type}_T1w_Warped \
	# 	-div temp_denominator \
	# 	${participant}_T1w.nii.gz

	# # Clean up and save the Affine and Warpfield for later
	# rm *Inverse*
	# rm temp*
	# mkdir -p warps
	# mv *mat warps
