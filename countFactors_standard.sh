#!/bin/bash
#SBATCH --partition=new,all
#SBATCH --output=/data/reddylab/Darryl/logs/counts.out

# This is the master SLURM script for collecting CWL pipeline data for insertion into
# ChIP-DB web application database. The data should be fetched from data directory in 
# the HARDAC directory '/data/reddylab/Alex/GGR/processing/chip_seq/'. Intended to be
# ran via `sbatch` command

source /data/reddylab/software/miniconda2/bin/activate alex
MY_DIR="$1"
OUT_DIR="$2"
mkdir -p ${OUT_DIR}
rsync -v ${MY_DIR}/*spp* ${OUT_DIR}
rsync -v ${MY_DIR}/qc.{csv,txt} ${OUT_DIR}
arr=($(/bin/ls -1 ${MY_DIR}/*bam.bai | \
         sed "s/.bai//" | \
         grep -v test | uniq))
numFactors=$((${#arr[@]}-1))
echo ${arr[@]}
echo ${numFactors}
sbatch --array=0-${numFactors}%50 \
        /data/reddylab/Darryl/GitHub/reddylab/bamFingerprint_plots_standard.sh \
        "$(echo ${arr[@]})" \
        ${MY_DIR} \
        ${OUT_DIR}
