#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=outlogs/myout_%a.out
OUT_DIR=/data/reddylab/Darryl/plots
MY_DIR=/data/reddylab/projects/GGR/data/chip_seq/mapped_reads/iter0
FACTORS=( $1 )
FACTOR=${FACTORS[${SLURM_ARRAY_TASK_ID}]}
echo "Files are: $(/bin/ls -1 ${MY_DIR}/${FACTOR}_*bam))"
labels=$(/bin/ls -1 ${MY_DIR}/${FACTOR}_*bam | sed "s@${MY_DIR}/@@" | cut -d '.' -f1,2)
echo "The factor is: ${FACTOR}"
echo "Replicates are: ${labels}"
plotFingerprint -b $(/bin/ls -1 ${MY_DIR}/${FACTOR}_*bam) \
	--labels ${labels} \
	-T "Fingerprints of ${FACTOR}" \
	-plot ${OUT_DIR}/${FACTOR}.png \
	--outRawCounts ${OUT_DIR}/${FACTOR}_counts.out	
