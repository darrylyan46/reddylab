#!/bin/bash
#SBATCH --partition=new,all
#SBATCH --output=/data/reddylab/Darryl/logs/std_%a.out

# This script is a subscript ran from `countFactors_standard.sh` for
# data insertion into the ChIP-DB web application. Intended for samples
# that follow the Reddy Lab sequencing sample naming conventions.

source /data/reddylab/software/miniconda2/bin/activate alex
FACTORS=( $1 )
METADATA="$2"
IN_DIR="$3"
OUT_DIR="$4"
FACTOR=${FACTORS[${SLURM_ARRAY_TASK_ID}]}
FACTOR_FILE=$(/bin/ls -1 ${IN_DIR}/${FACTOR}*.bam.bai | sed "s/.bai//")
# Extract all information out of metadata file
flowcell=$(grep "${FACTOR}" ${METADATA} |  cut -f1)
ip_ctrl=$(grep "${FACTOR}" ${METADATA} |  cut -f8)
ctrl=$(grep "${FACTOR}" ${METADATA} | cut -f9)
echo "Factor file is: ${FACTOR_FILE}"
echo "Factor label is: ${FACTOR}"
echo "Flowcell is: ${flowcell}, IP control is: ${ip_ctrl}, control is: ${ctrl}"
exit 0
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
