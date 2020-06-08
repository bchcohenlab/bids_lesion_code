[![DOI](https://zenodo.org/badge/257249924.svg)](https://zenodo.org/badge/latestdoi/257249924)
# This repository takes clinical T1 (T2, FLAIR) and DWI BIDS-formatted data and prepares it for lesion tracing.
Typically, I would recommend cloning this into `<bids-dir>/code` (I will update this to be `<bids-dir>/code/bids_lesion_code` in the future to match YODA principles.

## The main script is: `prep_for_ITKSNAP.sh`:

It cleans up T1w files, and T2 and FLAIR files if present, and stores them in:  
	`<bids_dir>/derivatives/lesions/<participant_id>/anat`

and generates/registers DWI, ADC, b0, and b1000 images to T1w space in:  
	`<bids_dir>/derivatives/lesions/<participant_id>/dwi`

For the T1w input, it expects the following naming convention:  
	`<bids_dir>/<participant_id>/anat/<participant_id>_T1w.nii.gz`  
	  
If this is not available, it will combine axial and coronal clinical scans into a 1mm iso T1:  
	`<bids_dir>/<participant_id>/anat/<participant_id>_acq-ax_T1w.nii.gz`  
	`<bids_dir>/<participant_id>/anat/<participant_id>_acq-sag_T1w.nii.gz`  

For the dwi input, it expects the following naming convention:  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_dwi.nii.gz`  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_desc-adc_dwi.nii.gz`  

Optional (if not present, will assume last frame is b = 1000):  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_dwi.bval`  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_desc-b0_dwi.nii.gz`  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_desc-b1000_dwi.nii.gz`  


## The files we want to use are:  
	`<bids_dir>/derivatives/lesions/<participant_id>/dwi/<participant_id>_T1w.nii.gz`  
	`<bids_dir>/derivatives/lesions/<participant_id>/dwi/<participant_id>_desc-b1000_dwi.nii.gz`  
	`<bids_dir>/derivatives/lesions/<participant_id>/dwi/<participant_id>_desc-adc_dwi.nii.gz`  
  
If you want to look at the T2w/FLAIR images in the same frame of reference, they are here:  
	`<bids_dir>/derivatives/lesions/<participant_id>/anat/<participant_id>_space-T1w_T2w.nii.gz`  
	`<bids_dir>/derivatives/lesions/<participant_id>/anat/<participant_id>_space-T1w_FLAIR.nii.gz`  

If you have both a B0 image and a B1000 image, you can try getting an automatic segmentation from DeepNeuro (requires a CUDA-capable card):
	`<bids_dir>/code/segment_with_DeepNeuro.sh <bids_dir>/derivatives/lesions/<participant_id>/dwi <participant_id>`

## And for now, name your lesion tracings with the following pattern:  
	`<bids_dir>/derivatives/lesions/<participant_id>/<participant_id>_space-T1w_desc-lesion<your_initials>_mask.nii.gz`  
  
To register individual-space T1ws and lesions to MNI space from BIDS-format, use:
	`<bids_dir>/code/ants_Lesion_in_T1w_space_to_MNI_bids.sh` (NOT FINISHED YET)
  
## (NON-BIDS QUICK SCRIPT): To register a single individual-space T1w and lesion to MNI space from specific dir, use:	
	`<working_dir>/code/ants_Lesion_in_T1w_space_to_MNI_quick.sh`
  
Either of these will change the "space" descriptor:  
`<bids_dir>/<participant_id>/dwi/<participant_id>_space-MNI152NLin2009cAsym_desc-lesion_mask.nii.gz`  
  
  
Several of these scripts are from: https://neuroimaging-core-docs.readthedocs.io/, which is a GREAT collection of tutorials and examples.  
  
Combining clinical T1w into a single HQ iso T1w is done with: https://github.com/gift-surg/NiftyMIC  

Registering T2, FLAIR, and DWI images to T1 is done with: https://github.com/ANTsX/ANTs `antsRegistrationSyNQuick.sh`

Initial segmentation of the DWI images is done with: https://github.com/QTIM-Lab/DeepNeuro/tree/master/deepneuro/pipelines/Ischemic_Stroke
