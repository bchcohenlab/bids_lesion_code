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
A_T1w_acq=$3
B_T1w_acq=$4
C_T1w_acq=$5

first=${working_dir}/${participant}_${A_T1w_acq}_T1w.nii.gz # This is the target T1w
second=${working_dir}/${participant}_${B_T1w_acq}_T1w.nii.gz # Another T1w
third=${working_dir}/${participant}_${C_T1w_acq}_T1w.nii.gz # 3rd T1w if applicable 

#### High quality fusion using niftymic:

# First, Make binary masks of where the two images have values:
if [ -z "$5" ]; then 
fslmaths \
	${first} \
	-abs \
	-bin \
	temp_${A_T1w_acq}_mask

fslmaths \
	${second} \
	-abs \
	-bin \
	temp_${B_T1w_acq}_mask


singularity exec \
	-B ${working_dir}:/app/data \
        -B ${BIDSPATH}:${BIDSPATH} \
	${BIDSPATH}/niftymic.sif \
	niftymic_reconstruct_volume \
		--filenames \
			/app/data/${participant}_acq-${A_T1w_acq}_T1w.nii.gz \
			/app/data/${participant}_acq-${B_T1w_acq}_T1w.nii.gz \
		--filenames-masks \
			/app/data/temp_${A_T1w_acq}_mask.nii.gz \
			/app/data/temp_${B_T1w_acq}_mask.nii.gz \
		--output \
			/app/data/${participant}_T1w.nii.gz
elif [ "$5" ]; then
fslmaths \
	${first} \
	-abs \
	-bin \
	temp_${A_T1w_acq}_mask

fslmaths \
	${second} \
	-abs \
	-bin \
	temp_${B_T1w_acq}_mask

fslmaths \
	${third} \
	-abs \
	-bin \
	temp_${C_T1w_acq}_mask


singularity exec \
	-B ${working_dir}:/app/data \
        -B ${BIDSPATH}:${BIDSPATH} \
	${BIDSPATH}/niftymic.sif \
	niftymic_reconstruct_volume \
		--filenames \
			/app/data/${participant}_${A_T1w_acq}_T1w.nii.gz \
			/app/data/${participant}_${B_T1w_acq}_T1w.nii.gz \
			/app/data/${participant}_${C_T1w_acq}_T1w.nii.gz \
		--filenames-masks \
			/app/data/temp_${A_T1w_acq}_mask.nii.gz \
			/app/data/temp_${B_T1w_acq}_mask.nii.gz \
			/app/data/temp_${C_T1w_acq}_mask.nii.gz \
		--output \
			/app/data/${participant}_T1w.nii.gz
fi

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
