#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=counts.out
MY_DIR=/data/reddylab/projects/GGR/data/chip_seq/mapped_reads/iter-1
arr=($(/bin/ls -1 ${MY_DIR}/*bam | cut -d '.' -f1,2 | grep -v test | uniq))
numFactors=$((${#arr[@]}-1))
echo ${arr[@]}
echo ${numFactors}
sbatch --array=0-${numFactors} bamFingerprint_plots_all.sh "$(echo ${arr[@]})"
