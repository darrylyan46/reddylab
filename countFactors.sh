#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=counts.out
source /data/reddylab/software/miniconda2/bin/activate alex
MY_DIR=/data/reddylab/projects/GGR/data/chip_seq/mapped_reads/iter0

arr=($(/bin/ls -1 ${MY_DIR}/*bam | sed "s@${MY_DIR}/@@" | sed "s/\_rep.*//" | cut -d '.' -f1,2 | grep -v test | uniq))
numFactors=$((${#arr[@]}-1))
echo ${arr[@]}
echo ${numFactors}
sbatch --array=0-${numFactors}%50 bamFingerprint_plots_all.sh "$(echo ${arr[@]})"
