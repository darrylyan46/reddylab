#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=outlogs/myout_%a.out
OUT_DIR="$3"
MY_DIR="$2"
FACTORS=( $1 )
FACTOR=${FACTORS[${SLURM_ARRAY_TASK_ID}]}
rep=$(echo ${FACTOR} | sed "s@${MY_DIR}/@@" | cut -d '_' -f 3,4)
ctrl=$(/bin/ls -1 ${MY_DIR}/*inputctrl*bam.bai | sed 's/.bai//')
ctrl_label=$(echo ${ctrl} | sed "s@${MY_DIR}/@@" | cut -d '.' -f 1)
factor_label=$(echo ${FACTOR} | sed "s@${MY_DIR}/@@" | cut -d '.' -f 1)
echo "The factor is: ${FACTOR}"
echo "Control is: ${ctrl}"
echo "The rep is: ${rep}"
echo "Labels are ${ctrl_label} ${factor_label}" 
plotFingerprint -b ${FACTOR} ${ctrl} \
	--labels ${factor_label} ${ctrl_label} \
	--outQualityMetrics ${OUT_DIR}/${factor_label}_QCmetrics.txt \
	--JSDsample ${ctrl} \
	-T "Fingerprint of ${factor_label}" \
	-plot ${OUT_DIR}/${factor_label}.png \
	--outRawCounts ${OUT_DIR}/${factor_label}_counts.tab	
