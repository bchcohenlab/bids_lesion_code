#!/bin/bash

################## 2/6/14 #########################
# Script by Evan Lutkenhoff, lutkenhoff@ucla.edu  #
# Monti Lab (http://montilab.psych.ucla.edu)      #
# Tools used within script are copyrighted by:    #
# FSL (http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSL) #
# & AFNI (http://afni.nimh.nih.gov/afni/)         #
###################################################
# This version was simplified by Dianne Patterson August 2018.
# It is expected by lesion_norm_fsl.sh

####PARSE options########################
#sets up initial values for brain extraction and MNI mask and debug
s1=bet; #default step1
mask=MNI152_T1_1mm_brain_mask.nii.gz; #default MNI mask
debugger=no; #default delete intermediate files

iopt=$1
i=`${FSLDIR}/bin/remove_ext $iopt`; #removes file extensions from input image
echo $i "is input image"

####END PARSE #################################


#### 1. initial brain extraction (“step 1”) #########################
## Perform initial “approximate” brain extraction (use FSL unless input options specify the AFNI option)
# this is referred to as “step 1” in the manuscript.

echo "step1 BET -B -f 0.1 subject ${i} for initial extraction"
bet ${iopt} ${i}_step1 -B -f 0.1

#
# #### 2. linear transform to MNI space (“step 2”) ####################
# ## Perform linear transformation of initial “approximate” extraction to MNI space
# # This is referred to as “step 2” in the manuscript.
#
echo "step2 flirt subject ${i} to MNI space"
flirt -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain -in ${i}_step1.nii.gz -omat ${i}_step2.mat -out ${i}_step2 -searchrx -30 30 -searchry -30 30 -searchrz -30 30
#
# #### 3. nonlinear transform to MNI space (“step 3”) ##################
# ## Follow the linear transformation with a non-linear transformation.  Use the MNI152 2mm as default
# # This is referred to as “step 3” in the manuscript
#
echo "step3 fnirt subject ${i} to MNI space"
fnirt --in=${i} --aff=${i}_step2.mat --cout=${i}_step3 --config=T1_2_MNI152_2mm
#
# #### 4. QC: Generate image for QC of fnirt ####################################
# ## This is a quality control step that generates an image of the original subject structural after transformation to MNI space
# # which can (and should) be checked by the user.
#
echo "step4 quality control of fnirt using applywarp to put subject ${i} in MNI space"
applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm --in=${i} --warp=${i}_step3 --out=${i}_step4
#
# #### 5. Invert nonlinear warp (“step 4a”) ############################
# ## Invert the nonlinear warp in order to be able to back-project the MNI brain into subject space
# # this is the first part of “step 4” in the manuscript
#
echo "step5 invert nonlinear warp for subject ${i}"
invwarp -w ${i}_step3.nii.gz -o ${i}_step5.nii.gz -r ${i}_step1.nii.gz
#
# #### 6. Apply inverted nonlinear warp to labels (“step 4b”) ##########
# ## Apply inverted nonlinear warp to the MNI standard brain in order to back-project it back into subject space
# # this is the second part of “step 4” in the manuscript
#
echo "step6 apply inverted nonlinear warp to MNI label: MNI152_T1_1mm_brain_mask for subject ${i}"
applywarp --ref=${i} --in=${FSLDIR}/data/standard/${mask} --warp=${i}_step5.nii.gz --out=${i}_step6 --interp=nn
#
# #### 7. binarize brain extractions ###################################
# ## Binarize the back-projected MNI brain in order to use it to “punch-out” brain extraction (in the next step)
#
echo "step 7 creating binary brain mask for subject ${i}"
fslmaths ${i}_step6.nii.gz -bin ${i}_optiBET_brain_mask
#
# #### 8. Punch-out mask from brain to do skull-stripping (“step 4c”) ##
# ## Take the binarized back-projected MNI brain and use it to “punch-out" non-brain tissue from the subject’s original T1 image
# # this is the last part of “step 4” as described in the manuscript).
#
echo "step 8 creating brain extraction for subject ${i}"
fslmaths ${i} -mas ${i}_optiBET_brain_mask ${i}_optiBET_brain

echo "removing intermediate files"
rm ${i}_step1.nii.gz ${i}_step1_mask.nii.gz ${i}_step2.nii.gz ${i}_step2.mat ${i}_step3.nii.gz ${i}_step4.nii.gz ${i}_step5.nii.gz ${i}_step6.nii.gz ${i}_to_MNI152_T1_2mm.log
