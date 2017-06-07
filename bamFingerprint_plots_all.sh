#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=myout_%a.out
OUT_DIR=/data/reddylab/Darryl/plots
MY_DIR=/data/reddylab/projects/GGR/data/chip_seq/mapped_reads/iter-1
FACTORS=( $1 )
FACTOR=$(basename ${FACTORS[${SLURM_ARRAY_TASK_ID}]})
labels= ${MY_DIR}/${FACTOR}*bam | cut
plotFingerprint -b ${MY_DIR}/${FACTOR}*bam \
	-plot ${OUT_DIR}/${FACTOR}.png \
	--outRawCounts ${OUT_DIR}/${FACTOR}_counts.out \
	-l
