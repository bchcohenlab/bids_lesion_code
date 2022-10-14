#!/bin/bash


: <<COMMENTBLOCK
Wrapper for scripts (many from https://neuroimaging-core-docs.readthedocs.io/) to prepare
T1w and dwi images in BIDS format for stroke lesion tracing in ITK-SNAP
COMMENTBLOCK

# If there are no arguments:
if [ $# -lt 1 ] ; then
	echo "Usage: $0 <bids_dir> <participant_id>"
	echo "e.g. prep_for_ITKSNAP.sh /Users/alex/data/lesions/WKTang_bids sub-001"
	echo "This script prepares a T1w image and DWI for lesion mapping."
	echo "It resamples the T1w to isovolumetric if needed, then "
	echo "reorients, bias corrects, and crops the T1w and also produces a "
	echo "quality brain mask that can be used to limit leakage of a lesion mask."
	echo "Then, it creates b0, b1000, and adc maps from a dwi file and registers"
	echo "these to the cleaned T1w image."
	echo "output:"
	echo "An anat dir in <bids_dir>/derivatives/lesions/<participant_id> containing:"
	echo "1) A cropped, reoriented, (resampled), and bias corrected head, e.g., sub-001_T1w.nii.gz,"
	echo "2) A brain mask, e.g., sub-001_space-T1w_desc-brain_mask.nii.gz, and"
	echo "3) A copy of the anisovol T1w (if converted), and an non-bias corrected version as well."
	echo ""
	echo "A dwi dir in <bids_dir>/derivatives/lesions/,participant_id> containing:"
	echo "1) Registered b0, b1000, and adc maps,"
	echo "2) A copy of the original unregistered dwi image, "
	echo "3) a sub-dir labeled: warps, that contains the registration affine and warpfields, and"
	echo "4) a copy of the corrected T1w and the associated mask."
	echo ""
	echo "Traced lesions should be labeled as: sub-001_space-T1w_desc-lesion_mask.nii.gz"


	echo "====================================="
	echo ""
	echo ""
	exit 1 ;
fi

bids_dir=$1
participant=$2

# Location of dataset code:
BIDSPATH=${bids_dir}/code # path to scripts
export PATH="$PATH:${BIDSPATH}"

# Expected input locations:
input_T1w=${bids_dir}/${participant}/anat/${participant}_T1w.nii.gz
input_dwi=${bids_dir}/${participant}/dwi/${participant}_dwi.nii.gz
input_b0=${bids_dir}/${participant}/dwi/${participant}_desc-b0_dwi.nii.gz
input_adc=${bids_dir}/${participant}/dwi/${participant}_desc-adc_dwi.nii.gz

# Output locations:
output_anat_dir=${bids_dir}/derivatives/lesions/${participant}/anat
output_dwi_dir=${bids_dir}/derivatives/lesions/${participant}/dwi
mkdir -p ${output_anat_dir}
mkdir -p ${output_dwi_dir}



###
# # Prepare the T1w (and T2w/FLAIR if present):
pushd ${output_anat_dir}

# Copy over the T1w, or make one if only clinical scans
if [ -f "$input_T1w" ]; then
 	cp $input_T1w .
else
	echo "*** No single T1w found, making a consolidated one ***"
	cp ${bids_dir}/${participant}/anat/${participant}_acq-*_T1w.nii.gz .
	count=1
	for i in `find . -name "*acq*T1*nii.gz"`; do 
		acq_${count}=`echo $i | rev | cut -d '_' -f2 | rev`
		count=$((count+1))
	done
	combine_clinical_ax_cor_T1w.sh ${output_anat_dir} ${participant} $acq1 $acq2 $acq3
	acq1= ; acq2= ; acq3=
fi


# if needed, make the T1w isovolumetric:
max_pixelwidth=`fslinfo ${participant}_T1w.nii.gz | grep pixdim[1-3] | awk '{ print $2 }' | sort -rn | head -1`
if [ $max_pixelwidth \> 1.5 ];
then 
	echo "largest pixel dimension is ${max_pixelwidth} > 1.5mm, reslicing to 1mm isovolumetric";
	iso.sh ${participant}_T1w.nii.gz 1
	mv ${participant}_T1w.nii.gz ${participant}_T1w_aniso.nii.gz
	mv ${participant}_T1w_1mm.nii.gz ${participant}_T1w.nii.gz
else
 	echo "largest pixel dimension is ${max_pixelwidth}, leaving image alone";
fi

# reorient, bias correct, and crop T1w and make a brain mask:
prep_T1w.sh ${participant}_T1w.nii.gz

# Change brain mask to BIDS compliant name
mv ${participant}_T1w_brain_mask.nii.gz ${participant}_space-T1w_desc-brain_mask.nii.gz

# clean up temp files:
rm -rf ${participant}_T1w.anat
mv ${participant}_T1w_orig.nii.gz ${participant}_desc-uncorrected_T1w.nii.gz


#If present, go ahead and warp the T2w and FLAIR to T1w space as well (these are usually low-res aniso):
input_T2w=${bids_dir}/${participant}/anat/${participant}_T2w.nii.gz
if [ -f "$input_T2w" ]; then
 	cp $input_T2w .
 	tag=T2w
 	ants_X_to_T1w.sh $output_anat_dir $participant $tag
else
	echo "*** FYI: No T2w found ***"
fi

input_FLAIR=${bids_dir}/${participant}/anat/${participant}_FLAIR.nii.gz
if [ -f "$input_FLAIR" ]; then
 	cp $input_FLAIR .
 	tag=FLAIR
 	ants_X_to_T1w.sh $output_anat_dir $participant $tag
else
	echo "*** FYI: No FLAIR found ***"
fi

popd
# ###



###
# Prepare the DWI:
pushd ${output_dwi_dir}
cp ${input_dwi} .

# Create b0 and b1000 maps if needed:
if [ -f "$input_b0" ]; then
 	cp $input_b0 .
else
 	dwi_b0.sh ${input_dwi}
fi

# Create adc map if needed:
if [ -f "$input_adc" ]; then
 	cp $input_adc .
else
 	dwi_adc.sh ${input_dwi}
fi

# Copy over the cleaned (and isovolumetric) T1w file:
cp ${output_anat_dir}/${participant}_T1w.nii.gz .
cp ${output_anat_dir}/${participant}_space-T1w_desc-brain_mask.nii.gz .

# Now register the b0 to the T1w and apply the transform to the adc and b1000 maps as well:
ants_dwi_to_T1w.sh $output_dwi_dir $participant


echo "You should be ready to go, use the following files in the ${output_dwi_dir} directory to trace lesions:"
echo "${participant}_T1w.nii.gz"
echo "${participant}_space-T1w_desc-b1000_dwi.nii.gz"
echo "${participant}_space-T1w_desc-adc_dwi.nii.gz"
echo "If you need to use the FLAIR or T2w images, those files are in ${output_anat_dir}"
