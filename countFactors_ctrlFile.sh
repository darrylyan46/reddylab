#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=counts.out
source /data/reddylab/software/miniconda2/bin/activate alex
MY_DIR="$1"
OUT_DIR="$2"
mkdir -p ${OUT_DIR}
arr=($(/bin/ls -1 ${MY_DIR}/*bam | sed "s@${MY_DIR}/@@" | cut -d '.' -f1,2 | grep -v test | uniq))
numFactors=$((${#arr[@]}-1))
echo ${arr[@]}
echo ${numFactors}
sbatch --array=0-${numFactors}%50 bamFingerprint_plots_ctrlFile.sh "$(echo ${arr[@]})" ${MY_DIR} ${OUT_DIR}
