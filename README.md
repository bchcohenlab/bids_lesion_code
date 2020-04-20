This repository takes clinical T1 and DWI  information and prepares it for lesion tracing.

The main script is: `prep_for_ITKSNAP.sh`:

It cleans up T1w files, and T2 and FLAIR files if present, and stores them in:
`<bids_dir>/derivatives/lesions/<participant_id>/anat`

and generates/registers DWI, ADC, b0, and b1000 images to T1w space in:
`<bids_dir>/derivatives/lesions/<participant_id>/dwi`

For the dwi input, it expects the following naming convention:
`<bids_dir>/<participant_id>/dwi/<participant_id>_dwi.nii.gz`
`<bids_dir>/<participant_id>/dwi/<participant_id>_desc-adc_dwi.nii.gz`

Optional (if not present, will assume last frame is b = 1000):
`<bids_dir>/<participant_id>/dwi/<participant_id>_dwi.bval`
`<bids_dir>/<participant_id>/dwi/<participant_id>_desc-b0_dwi.nii.gz`
`<bids_dir>/<participant_id>/dwi/<participant_id>_desc-b1000_dwi.nii.gz`

Some of these scripts are from: https://neuroimaging-core-docs.readthedocs.io/, which is a GREAT collection of tutorials and examples.

