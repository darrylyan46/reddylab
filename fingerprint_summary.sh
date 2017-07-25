#!/bin/bash
#SBATCH --output=/data/reddylab/Darryl/outlogs/summary.out
DIR="$1"
OUT_DIR="$2"
QC_files=($(/bin/ls -1 ${DATA}/*QCmetrics.txt*))
out=/data/reddylab/Darryl/fingerprint_QCsummary.tsv
echo "Number of files to process: ${#QC_files[@]}"
sed -n '1p' ${QC_files[0]} > ${out}
echo "Header is: $(sed -n '1p' ${QC_files[0]})"
for file in ${QC_files[@]}; do
	sed -n '2,3p' ${file};
done >> ${out}
