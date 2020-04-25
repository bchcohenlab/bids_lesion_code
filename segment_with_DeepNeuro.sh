#!/bin/bash

# Must be run on a CUDA-capable server with nvidia-docker installed
# USAGE: code/segment_with_DeepNeuro.sh /home_local/cohen/stroke_dwi_test/Dhand_bids/derivatives/lesions/sub-0197/dwi sub-0197
# (use absolute paths)

working_dir=$1
participant=$2

# Expected input locations:
b0=${participant}_space-T1w_desc-b0_dwi.nii.gz # This is the b0 image
b1000=${participant}_space-T1w_desc-b1000_dwi.nii.gz # This is the b1000 image

# Output location:
output_dir=${working_dir}/DeepNeuro
mkdir -p ${output_dir}

cp ${working_dir}/${b0} ${output_dir}
cp ${working_dir}/${b1000} ${output_dir}

# Run the DeepNeuro docker (requires CUDA)
docker run \
	--gpus all \
	--rm \
	-v ${output_dir}:/INPUT_DATA \
	qtimlab/deepneuro_segment_ischemic_stroke \
	segment_ischemic_stroke pipeline \
	-B0 /INPUT_DATA/${b0} \
	-DWI /INPUT_DATA/${b1000} \
	-output_folder /INPUT_DATA \
	-registered

#pushd ${output_dir}
#	for i in `find . -type f -name "*.gz"`; do 
#		echo converting $i to float32
#		fslmaths $i $i -odt float
#	done
#popd
