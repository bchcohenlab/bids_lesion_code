#!/bin/bash


export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12  # controls multi-threading

export ANTSPATH=/home/ch186161/bin/ants/bin/ # path to ANTs binaries
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS

echo This will use ${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS} threads at a time
echo Using the ANTs version installed at ${ANTSPATH}

temp_dir=./ants_Temp
mkdir -p $temp_dir

template=./icbm152_t1_tal_nlin_asym_09c_masked.nii.gz
orig=$1


# Generate linear and warp from original space to MNI152 target

antsRegistrationSyNQuick.sh \
	-d 3 \
	-m $orig_template \
	-f $template \
	-t s \
	-o ${orig_template_name}_to_MNI_ \
	-j 1 

mkdir -p ${Output_dir}/warps

# Then we apply the transform to bring the lesion mask into MNI152 space.

ls -1 $Lesion_dir | cut -d . -f -1 > list_of_subjects

for i in `cat list_of_subjects`; do 
	echo Working on subject: $i;
	antsApplyTransforms \
		-d 3 \
		-i ${Lesion_dir}/${i}.nii.gz \
		-r ${template} \
		-t ${orig_template_name}_to_MNI_1Warp.nii.gz \
		-t ${orig_template_name}_to_MNI_0GenericAffine.mat \
		-n GenericLabel[Linear] \
		-o ${i}_lesions_in_MNI.nii.gz
	mv ${i}* $Output_dir
done

mv ${orig_template_name}_to_MNI* ${Output_dir}/warps