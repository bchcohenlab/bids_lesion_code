#!/bin/bash


export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12  # controls multi-threading
export ANTSPATH=/programs/x86_64-linux/ants/2.3.1/bin/ # path to ANTs binaries

echo This will use ${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS} threads at a time
echo Using the ANTs version installed at ${ANTSPATH}

bids_dir=$1
participant_id=$2

other_space=${bids_dir}/code/JHU_MNI_SS_T1_brain_trimmed.nii.gz
other_space_name=MNI152EveAtlas

template=${bids_dir}/code/icbm152_t1_tal_nlin_asym_09c_masked.nii.gz
template_name=MNI152NLin2009cAsym

transform_type=b # I typically use "b": rigid + affine + deformable b-spline syn (3 stages)

# Generate linear and warp from original space to MNI152 target

if [ -f "${bids_dir}/derivatives/lesions/warps/${other_space_name}_${transform_type}_to_${template_name}_1Warp.nii.gz" ]; then
	echo Skipping Registration step, warp already exists
else
	echo Performing Registration from ${other_space_name} to ${template_name}
	antsRegistrationSyNQuick.sh \
		-d 3 \
		-m $other_space \
		-f $template \
		-t ${transform_type} \
		-o ${other_space_name}_${transform_type}_to_${template_name}_ \
		-j 1 
	mkdir -p ${bids_dir}/derivatives/lesions/warps
	mv ${other_space_name}_${transform_type}_to_${template_name}_* ${bids_dir}/derivatives/lesions/warps
fi



# Then we apply the transform to bring the lesion mask into MNI152 space.

echo Applying transform to subject: ${participant_id};
antsApplyTransforms \
	-d 3 \
	-i ${bids_dir}/derivatives/lesions/${participant_id}/${participant_id}_space-${other_space_name}_desc-lesion_mask.nii.gz \
	-r ${template} \
	-t ${bids_dir}/derivatives/lesions/warps/${other_space_name}_${transform_type}_to_${template_name}_1Warp.nii.gz \
	-t ${bids_dir}/derivatives/lesions/warps/${other_space_name}_${transform_type}_to_${template_name}_0GenericAffine.mat \
	-n NearestNeighbor \
	-o ${bids_dir}/derivatives/lesions/${participant_id}/${participant_id}_space-${template_name}_desc-lesion_mask.nii.gz



