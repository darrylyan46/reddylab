#!/bin/bash
METADATA_DIR="/data/reddylab/Alex/GGR/data/chip_seq/metadata/chip_seq_download_metadata.*"
PROCESSING_DIR="/data/reddylab/Alex/GGR/processing/chip_seq"
metadata_files=($(/bin/ls -1 ${METADATA_DIR}))
for file in ${metadata_files[@]}; do
	new_filename=${file##*/}
	experiment_name=$(echo ${new_filename} | cut -d '.' -f2)
	matching_experiments=($(/bin/ls -d \
			${PROCESSING_DIR}/${experiment_name}* 2>/dev/null))
	if [[ ${#matching_experiments[@]} -ne 0 ]] ; then
		for experiment in ${matching_experiments[@]}; do
			dir_name=${experiment##*/}
			echo "Submitted job: Metadata: ${file}, In dir: \
			 ${experiment}, Out dir: \ 
			 /data/reddylab/Darryl/GGR/analyses/fingerprint_and_spp/${dir_name}"
			 sbatch /data/reddylab/Darryl/GitHub/reddylab/countFactors_metadata.sh \
				${file} ${experiment} \
				/data/reddylab/Darryl/GGR/analysis/fingerprint_and_spp/${dir_name}
		done
	fi
done
exit 0 
