#!/bin/bash


export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12  # controls multi-threading
echo This will use ${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS} threads at a time
export ANTSPATH=/Users/alex/repos/opt/bin


## Inputs:
	bids_dir=$1
	participant_id=$2


## Derived file names and paths:
	template=${bids_dir}/code/icbm152_t1_tal_nlin_asym_09c_masked.nii.gz
	template_name=MNI152NLin2009cAsym

	working_dir=${bids_dir}/derivatives/lesions/${participant_id}/anat

	T1w_image=${working_dir}/${participant_id}_T1w.nii.gz
	T1w_image_name=${participant_id}_T1w

	T1w_brain_mask=${working_dir}/${participant_id}_space-T1w_desc-brain_mask.nii.gz
	T1w_brain=${working_dir}/${participant_id}_desc-SkullStripped_T1w.nii.gz


## Some Settings
	brain_extraction_tool="bet"
	# brain_extraction_tool="optibet"

	transform_type=b # I typically use "b": rigid + affine + deformable b-spline syn (3 stages)


# First generate rigid+affine+warp from your T1w to MNI152 target (both should be skull-stripped)

if [ -f "${bids_dir}/derivatives/lesions/warps/${T1w_image_name}_${transform_type}_to_${template_name}_1Warp.nii.gz" ]; then
	echo "Skipping Registration step, registration files already exist"
else
	
	if [ -f "${T1w_brain_mask}" ]; then
		echo "Skipping Brain Extraction step, Brain Mask already exists:"
		echo ${T1w_brain_mask}
	else
		
		if [ "$brain_extraction_tool" == "bet" ]; then
			echo "Performing Brain Extraction with bet"
			bet ${T1w_image} ${T1w_brain_mask}
			echo "if this is poor quality, consider using optiBET with lesion mask"
		
		elif [ "$brain_extraction_tool" == "optibet" ]; then
			echo "Running prep_T1w.sh to bias correct T1w and generate brain mask (needs lesion mask)"
			pushd ${working_dir}
				# Run prep_T1.sh using T1w and traced lesion to do brain extraction with optiBET
					prep_T1w.sh ${participant_id}_T1w.nii.gz ${bids_dir}/derivatives/lesions/${participant_id}/${participant_id}_space-T1w_desc-lesion_mask.nii.gz
				# Change brain mask to BIDS compliant name
					mv ${participant_id}_T1w_brain_mask.nii.gz ${participant_id}_space-T1w_desc-brain_mask.nii.gz
				# clean up temp files:
					rm -rf ${participant_id}_T1w.anat
					mv ${participant_id}_T1w_orig.nii.gz ${participant_id}_desc-uncorrected_T1w.nii.gz
			popd
		fi

	fi

	if [ -f "${T1w_brain}" ]; then
		echo "SkullStripped T1w already exists"
		echo ${T1w_brain}
	else
		echo "Making brain only image from ${T1w_image} for registration"
		fslmaths ${T1w_image} -mas ${T1w_brain_mask} ${T1w_brain}
	fi

	echo "Performing Registration from ${T1w_brain} to ${template_name}"
	antsRegistrationSyNQuick.sh \
		-d 3 \
		-m $T1w_brain \
		-f $template \
		-t ${transform_type} \
		-o ${T1w_image_name}_${transform_type}_to_${template_name}_ \
		-j 1 
	mkdir -p ${bids_dir}/derivatives/lesions/warps
	mv ${T1w_image_name}_${transform_type}_to_${template_name}_* ${bids_dir}/derivatives/lesions/warps
fi



# Then we apply the transform to bring the lesion mask into MNI152 space.

# echo Applying transform to subject: ${participant_id};
# antsApplyTransforms \
# 	-d 3 \
# 	-i ${bids_dir}/derivatives/lesions/${participant_id}/${participant_id}_space-T1w_desc-lesion_mask.nii.gz \
# 	-r ${template} \
# 	-t ${bids_dir}/derivatives/lesions/warps/${T1w_image_name}_${transform_type}_to_${template_name}_1Warp.nii.gz \
# 	-t ${bids_dir}/derivatives/lesions/warps/${T1w_image_name}_${transform_type}_to_${template_name}_0GenericAffine.mat \
# 	-n NearestNeighbor \
# 	-o ${bids_dir}/derivatives/lesions/${participant_id}/${participant_id}_space-${template_name}_desc-lesion_mask.nii.gz



