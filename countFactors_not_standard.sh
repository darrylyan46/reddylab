#!/bin/bash
#SBATCH --partition=new,all
#SBATCH --output=/data/reddylab/Darryl/logs/counts.out

# This is the master SLURM script for collecting CWL pipeline data for insertion into
# ChIP-DB web application database. The data should be fetched from data directory in
# the HARDAC directory '/data/reddylab/Alex/GGR/processing/chip_seq/'. Intended to be
# ran via `sbatch` command. This script is for directories that dont follow standard
# naming convention

source /data/reddylab/software/miniconda2/bin/activate alex
METADATA="$1"
MY_DIR="$2"
OUT_DIR="$3"
mkdir -p ${OUT_DIR}
rsync -v ${MY_DIR}/*spp* ${OUT_DIR}
rsync -v ${MY_DIR}/qc.{csv,txt} ${OUT_DIR}
# Read metadata file and extract factor namesi
factors=($(awk 'NR>=2 { print $3 }' ${METADATA}))
numFactors=$((${#factors[@]}-1))
echo ${factors[@]}
echo ${numFactors}
sbatch --array=0-${numFactors}%50 \
        /data/reddylab/Darryl/GitHub/reddylab/bamFingerprint_plots_not_standard.sh  \
        "$(echo ${factors[@]})" \
        ${METADATA} \
        ${MY_DIR} \
        ${OUT_DIR}
