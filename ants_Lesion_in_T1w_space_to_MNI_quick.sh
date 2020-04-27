#!/bin/bash

# If there are no arguments:
if [ $# -lt 1 ] ; then
	echo ""
	echo "Usage: $0 <working_dir> <T1w> <lesion>"
	echo "e.g.: code/ants_Lesion_in_T1w_space_to_MNI_quick.sh /Users/alex/projects/cclinic patient1_MRI.nii.gz patient1_segmentation.nii.gz"
	echo ""
	echo "NOTE: This script requires an isovolumetric T1w and a traced lesion in the same space."
	echo "NOTE: Give <working_dir> as an absolute path, and requires FSL and ants be set-up correctly"
	echo "NOTE: the BCHCohenLab lesion_tracing scripts must be in <working_dir>/code"
	echo "      which can be created by running: git clone https://github.com/bchcohenlab/bids_lesion_code.git code"
	echo "      (or you can change BIDSPATH in the script to point at this cloned repository)"
	echo ""
	echo "It reorients, bias corrects, and crops the T1w and also produces a relatively high quality"
	echo "brain mask that can be used for registration to limit leakage of a lesion mask. Then, it"
	echo "registers the T1w to MNI space, unweighting the lesion location, and applies this transform"
	echo "to the lesion as well. (Note that it's the ants INVERSE transform that is needed here)"
	echo ""
	echo "====================================="
	echo "Outputs:"
	echo "1)  A cropped, reoriented, and bias corrected head, e.g., sub-001_T1w.nii.gz,"
	echo "2)  A brain mask, e.g., sub-001_T1w_brain_mask.nii.gz,"
	echo "3)  A skull-stripped brain, e.g., sub-001_T1w_brain.nii.gz,"
	echo "4)  A copy of the original T1w image, e.g., sub-001_T1w_orig.nii.gz, and"
	echo "5)  The skull-stripped T1w brain in template (MNI) space, e.g., "
	echo ""
	echo "        sub-001_T1w_space-MNI152NLin2009cAsym_desc_desc-SkullStripped_T1w.nii.gz (BIDS-ish descriptors)."
	echo ""
	echo "6)  A copy of the original lesion image, e.g., sub-001_segmentation_orig.nii.gz,"
	echo "7)  A version of the lesion image in the cropped, reoriented T1w space, e.g., sub-001_segmentation.nii.gz,"
	echo "9)  a sub-dir labeled warps, that contains the registration affine and warpfields, and"
	echo "10) The lesion in template (MNI) space, e.g.,"
	echo ""
	echo "        sub-001_segmentation_space-MNI152NLin2009cAsym_desc-lesion_mask.nii.gz (BIDS-ish descriptors)."

	echo ""
	echo "Options that are hard-coded (but modifiable) in $0 include:"
	echo "where the code lives, which template to use, which brain extraction program to use, "
	echo "which ants transform_type to use, and how many CPU threads to use for ants."


	echo "====================================="
	echo ""
	echo "Source: Alex Cohen, alexander.cohen2@childrens.harvard.edu"
	echo "        Script was first published 4/27/2020 on GitHub at:"
	echo "        https://github.com/bchcohenlab/bids_lesion_code.git"
	echo ""
	exit 1 ;
fi

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=12  # controls multi-threading
echo This will use ${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS} threads at a time
export ANTSPATH=/Users/alex/repos/opt/bin



# Requires FSL and ants be set-up correctly

## Inputs:
	working_dir=$1
	
	T1w_image=$2
	lesion=$3

	# template=$3
	# template_name=$4
	
	template=code/icbm152_t1_tal_nlin_asym_09c_masked.nii.gz
	template_name=MNI152NLin2009cAsym # assuming you use the icbm152_t1_tal_nlin_asym_09c_masked.nii.gz file
	

## Some Settings
	# brain_extraction_tool="bet" # Works fast and is typically adequate for HQ T1w and brains with small lesions
	brain_extraction_tool="optibet" # Slower and works better when there are large lesions
	
	transform_type=b # I typically use "b": rigid + affine + deformable b-spline syn (3 stages); but "s" sometimes works better

	BIDSPATH=${working_dir}/code # path to scripts
	chmod -f a+x ${BIDSPATH}/*sh
	export PATH="$PATH:${BIDSPATH}"


## Derived file names and paths:
	T1w_image_name=`remove_ext ${T1w_image}`
	T1w_brain_mask=${working_dir}/${T1w_image_name}_brain_mask.nii.gz
	T1w_brain=${working_dir}/${T1w_image_name}_brain.nii.gz
	lesion_name=`remove_ext ${lesion}`



## START OF CODE THAT ACTUALLY DOES STUFF:

# First generate rigid+affine+warp from your T1w to MNI152 target (both should be skull-stripped)
pushd ${working_dir}

if [ -f "${working_dir}/warps/${template_name}_${transform_type}_to_${T1w_image_name}_1Warp.nii.gz" ]; then
	echo "Skipping Registration step, registration files already exist"
else
	
	if [ -f "${T1w_brain_mask}" ]; then
		echo "Skipping Brain Extraction step, Brain Mask already exists:"
		echo ${T1w_brain_mask}
	else
		
		if [ "$brain_extraction_tool" == "bet" ]; then
			echo "Performing Brain Extraction with bet"
			bet ${T1w_image} ${T1w_brain_mask} -m
			echo "if this is poor quality, consider using optiBET with lesion mask"
		
		elif [ "$brain_extraction_tool" == "optibet" ]; then
			echo "Running prep_T1w.sh to bias correct T1w and generate brain mask with optiBET (using lesion mask)"
			prep_T1w.sh ${T1w_image} ${lesion}
			rm -rf ${T1w_image_name}.anat # clean up temp files
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
	echo "# In the SyNQuick script, the mask applies to fixed image,"
	echo "so the template=moving is moving to the subject=fixed, and "
	echo "the inverse warp is what we'll want to apply to the lesion data."

	temp_dir=./ants_Temp
	mkdir -p $temp_dir

	inverse_lesion=${temp_dir}/${T1w_image_name}_inverse_lesion.nii.gz
	lesion_masked_T1w_brain=${temp_dir}/${T1w_image_name}_lesioned.nii.gz

	echo "Making lesion masked T1w brain image"
	ImageMath 3 ${inverse_lesion} Neg ${lesion} # output first
	MultiplyImages 3 ${T1w_brain} ${inverse_lesion} ${lesion_masked_T1w_brain} # output last

	antsRegistrationSyNQuick.sh \
		-d 3 \
		-m ${template} \
		-f ${lesion_masked_T1w_brain} \
		-t ${transform_type}\
		-o ${template_name}_${transform_type}_to_${T1w_image_name}_ \
		-x ${inverse_lesion} \
		-j 1 

	mkdir -p ./warps
	mv ${template_name}_${transform_type}_to_${T1w_image_name}_* ./warps
	cp ./warps/${template_name}_${transform_type}_to_${T1w_image_name}_InverseWarped.nii.gz ${T1w_image_name}_space-${template_name}_desc-SkullStripped_T1w.nii.gz
	rm -rf ants_Temp
fi



# Then we apply the transform to bring the lesion mask into MNI152 space.

echo "Applying transform to ${lesion}"
antsApplyTransforms \
	-d 3 \
	-i ${lesion} \
	-r ${template} \
	-t [./warps/${template_name}_${transform_type}_to_${T1w_image_name}_0GenericAffine.mat, 1] \
	-t ./warps/${template_name}_${transform_type}_to_${T1w_image_name}_1InverseWarp.nii.gz \
	-n NearestNeighbor \
	-o ${lesion_name}_space-${template_name}_desc-lesion_mask.nii.gz

echo "Reducing any FLOAT64 images to FLOAT32; segmentations can be reduced further, but they are already small"
float64_to_float32.sh

popd

