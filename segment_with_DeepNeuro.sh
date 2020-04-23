#!/bin/bash

working_dir=$1
participant=$2

# Expected input locations:
b0=${participant}_space-T1w_desc-b0_dwi.nii.gz # This is the b0 image
b1000=${participant}_space-T1w_desc-b1000_dwi.nii.gz # This is the b1000 image

# Output location:
output_dir=${working_dir}/DeepNeuro
mkdir -p ${output_dir}

# Run the DeepNeuro docker (requires CUDA)
docker run \
	--gpus all \
	--rm \
	-v ${working_dir}:/INPUT_DATA \
	qtimlab/deepneuro_segment_ischemic_stroke \
	segment_ischemic_stroke pipeline \
	-B0 /INPUT_DATA/${b0} \
	-DWI /INPUT_DATA/${b1000} \
	-output_folder /INPUT_DATA/DeepNeuro \
	-registered

