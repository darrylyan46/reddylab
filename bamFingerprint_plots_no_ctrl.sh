#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=/data/reddylab/Darryl/outlogs/no_ctrl%a.out
DIR="$1"
OUT_DIR="$3"
FACTORS=( $2 )
FACTOR=${FACTORS[${SLURM_ARRAY_TASK_ID}]}
files=($(/bin/ls -1 ${DIR}/${FACTOR}*bam.bai | sed "s/.bai//"))
labels=($(/bin/ls -1 ${DIR}/${FACTOR}*bam.bai | sed "s@${DIR}/@@" | cut -d '.' -f1,2))
echo "The factor is: ${FACTOR}"
echo "The labels are: ${labels[@]}"
echo "Files are: ${files[@]}"
echo "There are: ${#files[@]} files"
plotFingerprint -b ${files[@]} \
        --labels ${labels[@]} \
        --outQualityMetrics ${OUT_DIR}/${FACTOR}_QCmetrics.txt \
        -T "Fingerprint of ${FACTOR}" \
        -plot ${OUT_DIR}/${FACTOR}.png \
        --outRawCounts ${OUT_DIR}/${FACTOR}_counts.tab
