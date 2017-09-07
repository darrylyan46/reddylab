#!/bin/bash
#SBATCH --partition=new,all
#SBATCH --output=/data/reddylab/Darryl/logs/std_%a.out

# This script is a subscript ran from `countFactors_standard.sh` for
# data insertion into the ChIP-DB web application. Intended for samples
# that follow the Reddy Lab sequencing sample naming conventions.

source /data/reddylab/software/miniconda2/bin/activate alex
OUT_DIR="$3"
MY_DIR="$2"
FACTORS=( $1 )
factor_file=${FACTORS[${SLURM_ARRAY_TASK_ID}]}
FACTOR=$(echo ${factor_file} | sed "s@${MY_DIR}/@@")
cell=$(echo "${FACTOR}" | cut -d '.' -f 1)
experiment=$(echo "${FACTOR}" | cut -d '.' -f 2)
treat=$(echo "${FACTOR}" | cut -d '.' -f 3)
hr=$(echo "${FACTOR}" | cut -d '.' -f 4)
rep=$(echo "${FACTOR}" | cut -d '.' -f 5)
ip_ctrl=$(/bin/ls -1 ${MY_DIR}/*${cell}*{IP,Ip,ip}*{CTRL,Ctrl,ctrl}*${hr}*${rep}*bam.bai | \
         sed 's/.bai//')
input_ctrl=$(/bin/ls -1 ${MY_DIR}/*${cell}*{INPUT,Input,input}*{CTRL,Ctrl,ctrl}*${hr}*${rep}*bam.bai | \
         sed 's/.bai//')
factor_label=$(echo ${FACTOR} | \
	cut -d '.' -f 1,2,3,4,5)
echo "Cell is: ${cell}, experiment is: ${experiment}, treatment is: ${treat}, hour is: ${hr}, replicate is: ${rep}"
echo "Factor file is: ${factor_file}"
# Case where treatment is a control sample
if [ "${factor_file}" = "${ip_ctrl}" ] \
|| [ "${factor_file}" = "${input_ctrl}" ];
then
	echo "Sample ${factor_file} is a control"
	plotFingerprint -b ${factor_file} \
        --labels ${factor_label}  \
        --outQualityMetrics ${OUT_DIR}/${factor_label}_QCmetrics.txt \
        -T "Fingerprint of ${factor_label}" \
        -plot ${OUT_DIR}/${factor_label}.png \
        --outRawCounts ${OUT_DIR}/${factor_label}_counts.tab
	exit 0
fi
# Case where sample has IP control and Input control
if [ -n "${ip_ctrl}" ] && [ -n "${input_ctrl}" ];
then
	echo "Sample, ${factor_file}, has IP control ${ip_ctrl} and \
	input control ${input_ctrl}"
	ip_ctrl_label=$(echo ${ip_ctrl} | \
        sed "s@${MY_DIR}/@@" | \
        cut -d '.' -f 1,2,3,4,5)
	input_ctrl_label=$(echo ${input_ctrl} | \
        sed "s@${MY_DIR}/@@" | \
        cut -d '.' -f 1,2,3,4,5)
	plotFingerprint -b ${factor_file} ${ip_ctrl} ${input_ctrl} \
	--labels ${factor_label} ${ip_ctrl_label} ${input_ctrl_label} \
	--outQualityMetrics ${OUT_DIR}/${factor_label}_QCmetrics.txt \
	--JSDsample ${input_ctrl} \
	-T "Fingerprint of ${factor_label}" \
	-plot ${OUT_DIR}/${factor_label}.png \
	--outRawCounts ${OUT_DIR}/${factor_label}_counts.tab
# Case where sample has w/ IP control and no Input control
elif [ -n "${ip_ctrl}" ] && [ -z "${input_ctrl}" ];
then
	echo "Sample, ${factor_file}, has IP control ${ip_ctrl}"
        ip_ctrl_label=$(echo ${ip_ctrl} | \
        sed "s@${MY_DIR}/@@" | \
        cut -d '.' -f 1,2,3,4,5)
        plotFingerprint -b ${factor_file} ${ip_ctrl} \
        --labels ${factor_label} ${ip_ctrl_label}  \
        --outQualityMetrics ${OUT_DIR}/${factor_label}_QCmetrics.txt \
        --JSDsample ${ip_ctrl} \
        -T "Fingerprint of ${factor_label}" \
        -plot ${OUT_DIR}/${factor_label}.png \
        --outRawCounts ${OUT_DIR}/${factor_label}_counts.tab
# Case where sample has w/ Input control and no IP control
elif [ -z "${ip_ctrl}" ] && [ -n "${input_ctrl}" ];
then
	echo "Sample, ${factor_file}, has Input control ${input_ctrl}"
	input_ctrl_label=$(echo ${input_ctrl} | \
        sed "s@${MY_DIR}/@@" | \
        cut -d '.' -f 1,2,3,4,5)
        plotFingerprint -b ${factor_file} ${input_ctrl} \
        --labels ${factor_label} ${input_ctrl_label}  \
        --outQualityMetrics ${OUT_DIR}/${factor_label}_QCmetrics.txt \
        --JSDsample ${input_ctrl} \
        -T "Fingerprint of ${factor_label}" \
        -plot ${OUT_DIR}/${factor_label}.png \
        --outRawCounts ${OUT_DIR}/${factor_label}_counts.tab
# Case where sample has no control
else
	echo "Sample, ${factor_file}, has no Input or IP control"
	plotFingerprint -b ${factor_file} \
        --labels ${factor_label}  \
        --outQualityMetrics ${OUT_DIR}/${factor_label}_QCmetrics.txt \
        -T "Fingerprint of ${factor_label}" \
        -plot ${OUT_DIR}/${factor_label}.png \
        --outRawCounts ${OUT_DIR}/${factor_label}_counts.tab
fi

exit 0
