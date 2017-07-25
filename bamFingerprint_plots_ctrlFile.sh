#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=outlogs/myout_%a.out
OUT_DIR="$3"
MY_DIR="$2"
CTRL_FILE=/data/reddylab/projects/GGR/data/chip_seq/metadata/trt_to_ctrl.txt
FACTORS=( $1 )
FACTOR=${FACTORS[${SLURM_ARRAY_TASK_ID}]}
ctrl=$(grep "${FACTOR}" ${CTRL_FILE} | grep -v nan | cut -f2)
factor_file=$(/bin/ls -1 ${MY_DIR}/${FACTOR}*.bam)
ctrl_file=$(/bin/ls -1 ${MY_DIR}/${ctrl}*.bam)
file_limit=1
echo "The factor is: ${FACTOR}"
echo "Control is: ${ctrl}"
echo "The files are ${factor_file} ${ctrl_file}"
echo "Labels are ${FACTOR} ${ctrl}"
if [ "${#ctrl_file[@]}" -ne ${file_limit} ];
then
	plotFingerprint -b ${factor_file} \
        --labels ${FACTOR} \
        --outQualityMetrics ${OUT_DIR}/${FACTOR}_QCmetrics.txt \
        -T "Fingerprint of ${FACTOR}" \
        -plot ${OUT_DIR}/${FACTOR}.png \
        --outRawCounts ${OUT_DIR}/${FACTOR}_counts.tab
else
	plotFingerprint -b ${factor_file} ${ctrl_file} \
        --labels ${FACTOR} ${ctrl} \
        --outQualityMetrics ${OUT_DIR}/${FACTOR}_QCmetrics.txt \
        --JSDsample ${ctrl_file} \
        -T "Fingerprint of ${FACTOR}" \
        -plot ${OUT_DIR}/${FACTOR}.png \
        --outRawCounts ${OUT_DIR}/${FACTOR}_counts.tab
fi
