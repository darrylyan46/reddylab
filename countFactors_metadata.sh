#!/bin/bash
#SBATCH --partition=new,all
#SBATCH --output=/data/reddylab/Darryl/logs/counts.out

# This is the master SLURM script for collecting CWL pipeline data for insertion into
# ChIP-DB web application database. The data should be fetched from data directory in 
# the HARDAC directory '/data/reddylab/Alex/GGR/processing/chip_seq/'. Intended to be
# ran via `sbatch` command

source /data/reddylab/software/miniconda2/bin/activate alex
METADATA="$1"
IN_DIR="$2"
OUT_DIR="$3"
mkdir -p ${OUT_DIR}
for file in ${IN_DIR}/*spp*; do
	ln -s ${file} ${OUT_DIR}
done
for file in ${IN_DIR}/qc.{csv,txt} do
	if [ -e ${file} ]
	 then
		ln -s ${file} ${OUT_DIR}
	fi
done
# ln -s $(echo ${IN_DIR}/*spp*) ${OUT_DIR}
# ln -s $(echo ${IN_DIR}/qc.{csv,txt}) ${OUT_DIR}
# Subtract twice, one for header line and one due to 0-based indexing
NUM_LINES_METADATA=$(wc -l < ${METADATA})
NUM_SAMPLES=$((NUM_LINES_METADATA - 1))
echo ${NUM_SAMPLES}
sbatch --array=0-${NUM_SAMPLES}%5 \
        /data/reddylab/Darryl/GitHub/reddylab/bamFingerprint_plots_metadata.sh  \
	${METADATA} \
        ${IN_DIR} \
        ${OUT_DIR}
