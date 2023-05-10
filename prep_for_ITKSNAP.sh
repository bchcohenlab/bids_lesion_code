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
BIDSPATH=${bids_dir}/code/bids_lesion_code # path to scripts
export PATH="$PATH:${BIDSPATH}"


# Expected input locations:
input_T1w=${bids_dir}/${participant}/anat/${participant}_T1w.nii.gz
input_dwi=${bids_dir}/${participant}/dwi/${participant}_dwi.nii.gz
input_b0=${bids_dir}/${participant}/dwi/${participant}_desc-b0_dwi.nii.gz
input_adc=${bids_dir}/${participant}/dwi/${participant}_desc-adc_dwi.nii.gz
input_T2w=${bids_dir}/${participant}/anat/${participant}_T2w.nii.gz
input_FLAIR=${bids_dir}/${participant}/anat/${participant}_FLAIR.nii.gz
input_T1w_clin=${bids_dir}/${participant}/anat/${participant}_acq-*_T1w.nii.gz # GM - eh

# Output locations:
output_anat_dir=${bids_dir}/derivatives/lesions/${participant}/anat
output_dwi_dir=${bids_dir}/derivatives/lesions/${participant}/dwi





###

mkdir -p ${output_anat_dir}

# # Prepare the T1w (and T2w/FLAIR if present):
pushd ${output_anat_dir}

if [ -f "$input_T1w" ]; then
	reg_target=T1w
	echo "Registration Target is T1w"
else
	reg_target=T2w
	echo "Registration Target is T2w"
fi

# Copy over the Registration image, or make one if only clinical scans
if [ -f "$input_T1w" ]; then
 	cp $input_T1w .
elif [ -f "$input_T1w_clin" ]; then
	echo "*** No single T1w found, making a consolidated one ***"
	#cp ${bids_dir}/${participant}/anat/${participant}_acq-*_T1w.nii.gz .
	#count=1
	#for i in `find . -name "*acq*T1*nii.gz"`; do 
	#	eval acq${count}=`echo $i | rev | cut -d '_' -f2 | rev`
	#	count=$((count+1))
	#done
	#echo "*** Consolidating $acq1 $acq2 $acq3 ***"
	#combine_clinical_ax_cor_T1w.sh ${output_anat_dir} ${participant} $acq1 $acq2 $acq3 #GM - make loop in this script better (ex in ants_dwi_to_t1w.sh?)
	#acq1= ; acq2= ; acq3=
else
	echo "*** No T1w found ***"
fi

if [ -f "$input_T2w" ]; then
 	cp $input_T2w .
else
	echo "*** No T2w found ***"
	#Combine clinical
fi

# if needed, make the T1w isovolumetric:
max_pixelwidth=`fslinfo ${participant}_${reg_target}.nii.gz | grep pixdim[1-3] | awk '{ print $2 }' | sort -rn | head -1`
if [ $max_pixelwidth \> 1.5 ];
then 
	echo "largest pixel dimension is ${max_pixelwidth} > 1.5mm, reslicing to 1mm isovolumetric";
	iso.sh ${participant}_${reg_target}.nii.gz 1
	mv ${participant}_${reg_target}.nii.gz ${participant}_${reg_target}_aniso.nii.gz
	mv ${participant}_${reg_target}_1mm.nii.gz ${participant}_${reg_target}.nii.gz
else
 	echo "largest pixel dimension is ${max_pixelwidth}, leaving image alone";
fi


#if [[ $reg_target = "T1w" ]]; then
	# reorient, bias correct, and crop T1w and make a brain mask:
	prep_T1w.sh ${participant}_${reg_target}.nii.gz 
	
	# Change brain mask to BIDS compliant name
	mv ${participant}_${reg_target}_brain_mask.nii.gz ${participant}_space-${reg_target}_desc-brain_mask.nii.gz
	
	# clean up temp files:
	rm -rf ${participant}_${reg_target}.anat
	mv ${participant}_${reg_target}_orig.nii.gz ${participant}_desc-uncorrected_${reg_target}.nii.gz 
#else
	#T2=${participant}_T2w.nii.gz
	
	# reorient T2w and make a brain mask and skull stripped image
	#date; echo "Reorienting to standard orientation"
    	#run $FSLDIR/bin/fslmaths ${T2} ${T2}_orig
    	#run $FSLDIR/bin/fslreorient2std ${T2} > ${T2}_orig2std.mat
    	#run $FSLDIR/bin/convert_xfm -omat ${T2}_std2orig.mat -inverse ${T2}_orig2std.mat
    	#run $FSLDIR/bin/fslreorient2std ${T2} ${T2}
	
	#mri_synthstrip -i ${participant}_T2w.nii.gz -o ${participant}_space-T2w_desc-SkullStripped.nii.gz -m ${participant}_space-T2w_desc-brain_mask.nii.gz
	
	# clean up temp files
	#rm ${participant}_T2w.nii.gz_orig2std.mat
	
	# move skull stripped image 
	#mv ${participant}_space-T2w_desc-SkullStripped.nii.gz ${bids_dir}/derivatives/lesions/${participant}/
#fi




# Register T2w and FLAIR to subject space
if reg_target=T1w; then
	if [ -f "$input_T2w" ]; then
 		tag=T2w
 		ants_X_to_T1w.sh $output_anat_dir $participant $tag
	else
		echo "*** FYI: No T2w found ***"
	fi

	if [ -f "$input_FLAIR" ]; then
 		cp $input_FLAIR .
 		tag=FLAIR
 		ants_X_to_T1w.sh $output_anat_dir $participant $tag $reg_target
	else
		echo "*** FYI: No FLAIR found ***"
	fi

elif reg_target=T2w; then
	if [ -f "$input_FLAIR" ]; then
 		cp $input_FLAIR .
 		tag=FLAIR
 		ants_X_to_T1w.sh $output_anat_dir $participant $tag $reg_target
	else
		echo "*** FYI: No FLAIR found ***"
	fi
fi
	

popd
# ###

#exit if no DWI (i.e. for chronic scans)

if [ -f "$input_dwi" ]; then
	echo "**** FYI no DWI found ****"
	exit
fi

###
# Prepare the DWI:

mkdir -p ${output_dwi_dir}

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
cp ${output_anat_dir}/${participant}_${reg_target}.nii.gz .
cp ${output_anat_dir}/${participant}_space-${reg_target}_desc-brain_mask.nii.gz .

# Now register the b0 to the T1w and apply the transform to the adc and b1000 maps as well:
ants_dwi_to_T1w.sh $output_dwi_dir $participant $reg_target 


echo "You should be ready to go, use the following files in the ${output_dwi_dir} directory to trace lesions:"
echo "${participant}_T1w.nii.gz"
echo "${participant}_space-T1w_desc-b1000_dwi.nii.gz"
echo "${participant}_space-T1w_desc-adc_dwi.nii.gz"
echo "If you need to use the FLAIR or T2w images, those files are in ${output_anat_dir}"
