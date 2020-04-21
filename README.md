# This repository takes clinical T1 (T2, FLAIR) and DWI BIDS-formatted data and prepares it for lesion tracing.
Typically, I would recommend cloning this into bids-dir/code

## The main script is: `prep_for_ITKSNAP.sh`:

It cleans up T1w files, and T2 and FLAIR files if present, and stores them in:  
	`<bids_dir>/derivatives/lesions/<participant_id>/anat`

and generates/registers DWI, ADC, b0, and b1000 images to T1w space in:  
	`<bids_dir>/derivatives/lesions/<participant_id>/dwi`


### For the T1w input, it expects the following naming convention:  
	`<bids_dir>/<participant_id>/anat/<participant_id>_T1w.nii.gz`  
	  
If this is not available, it will combine axial and coronal clinical scans into a 1mm iso T1:  
	`<bids_dir>/<participant_id>/anat/<participant_id>_acq-ax_T1w.nii.gz`  
	`<bids_dir>/<participant_id>/anat/<participant_id>_acq-sag_T1w.nii.gz`


### For the dwi input, it expects the following naming convention:  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_dwi.nii.gz`  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_desc-adc_dwi.nii.gz` 

Optional (if not present, will assume last frame is b = 1000):  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_dwi.bval`  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_desc-b0_dwi.nii.gz`  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_desc-b1000_dwi.nii.gz` 


## Traced lesions should be named with the following pattern:  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_space-T1w_desc-lesion_mask.nii.gz`

when we register these to MNI space, we will change the "space" descriptor:  
	`<bids_dir>/<participant_id>/dwi/<participant_id>_space-MNI152NLin2009cAsym_desc-lesion_mask.nii.gz`

Some of these scripts are from: https://neuroimaging-core-docs.readthedocs.io/, which is a GREAT collection of tutorials and examples.

Combining clinical T1w into iso T1w is done with: https://github.com/gift-surg/NiftyMIC  
Registering T2, FLAIR, and DWI images to T1 is done with: https://github.com/ANTsX/ANTs `antsRegistrationSyNQuick.sh`
