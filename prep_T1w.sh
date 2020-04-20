#!/bin/bash

: <<COMMENTBLOCK
Call fsl_anat_alt.sh and optiBET.sh to reorient, bias correct and crop the T1w image.
And we generate a brain mask that can be used to limit the spread of the lesion we will draw.
Assume we are in the directory with the images we need.
COMMENTBLOCK

# If there are no arguments
if [ $# -lt 1 ] ; then
  echo "Usage: $0 <T1w_image>"
  echo "e.g. prep_T1w.sh sub-001_T1w.nii.gz"
  echo "This script prepares the T1w image for lesion mapping."
  echo "It calls fsl_anat_alt.sh and optiBET.sh to reorient, "
  echo "bias correct, and crop a T1w image and also to produce a "
  echo "quality brain mask that can be used to limit leakage of a lesion mask."
  echo "output:"
  echo "1) A subdirectory containing the results of running the processing steps"
  echo "2) brain mask, e.g., sub-001_T1w_brain_mask.nii.gz"
  echo "3) backup of original head: e.g., sub-001_T1w.nii.gz->sub-001_T1w_orig.nii.gz"
  echo "4) cropped, reoriented and bias corrected head, e.g., sub-001_T1w.nii.gz"
 echo "====================================="
  echo "optionally, provide a lesion mask to get cropped:"
  echo "e.g. prep_T1w.sh sub-001_T1w.nii.gz lesion.nii.gz"
  exit 1 ;
fi

stem=`remove_ext ${1}`
mask_stem=`remove_ext ${2}`

if [ ! -d ${stem}.anat ] ; then
  if [ $# -eq 1 ]; then
    # run our super spiffy fsl_anat_alt.sh with optiBET.sh
    echo "running prep on anatomical image only"
    fsl_anat_alt.sh -i ${stem} --nosubcortseg --noseg
  elif [ $# -eq 2 ]; then
    # run our super spiffy fsl_anat_alt.sh with optiBET.sh
    echo "running prep on anatomical image and lesion mask"
    fsl_anat_alt.sh -i ${stem} -m ${mask_stem} --nosubcortseg --noseg
    immv ${mask_stem} ${mask_stem}_orig
    imcp ${stem}.anat/lesionmask.nii.gz ${mask_stem}.nii.gz
  fi
fi
# copy the best native space brain mask from the subdir.
# This result mask is from fsl_anat not just optibet.
imcp ${stem}.anat/T1_biascorr_brain_mask.nii.gz ${stem}_brain_mask.nii.gz
fslmaths ${stem}_brain_mask.nii.gz ${stem}_brain_mask.nii.gz -odt char
# also replace the T1w image with the bias corrected, reoriented and cropped version
immv ${stem} ${stem}_orig
immv ${stem}.anat/T1_biascorr.nii.gz ${stem}.nii.gz
fslmaths ${stem}.nii.gz ${stem}.nii.gz -odt short
