#!/bin/bash

: <<COMMENTBLOCK
This code calls flirt to reslice an image into the space of another image
COMMENTBLOCK


# Exit if number of arguments is too small
if [ $# -lt 2 ]
    then
        echo "======================================================"
        echo "Two arguments are required."
        echo "argument 1: name of NIFTI image to reslice"
        echo "argument 2: name of NIFTI image in the target space"
        echo "e.g., $0 anat_CT_coronal anat_CT_axial"
        echo "output will be named with _resliced appended"
        echo "It assumes they are virtually aligned"
        echo "for those cases where the 'virtually aligned' choice in reslice.sh"
        echo "creates problems, try reslice_alt.sh."
        echo "12 DOF used here is good for gantry tilt correction of CT images."
        echo "======================================================"
        exit 1
fi

# get the input stem
input=`remove_ext ${1}`
target=`remove_ext ${2}`

# If there are 2 arguments, then we are reslicing an anatomical image, not a mask
if [ $# -eq 2 ]; then
  flirt -in ${input} -ref ${target} -out ${input}_resliced -omat ${input}_resliced.mat -bins 256 -cost corratio -searchrx 0 0 -searchry 0 0 -searchrz 0 0 -dof 12  -interp trilinear

  fslmaths ${input}_resliced.nii.gz ${input}_resliced.nii.gz -odt short
fi
