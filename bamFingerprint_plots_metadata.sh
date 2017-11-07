#!/bin/bash
#SBATCH --partition=new,all
#SBATCH --output=/data/reddylab/Darryl/logs/std_%a.out

# This script is a subscript ran from `countFactors_standard.sh` for
# data insertion into the ChIP-DB web application. Intended for samples
# that follow the Reddy Lab sequencing sample naming conventions.

source /data/reddylab/software/miniconda2/bin/activate alex
METADATA="$1"
IN_DIR="$2"
OUT_DIR="$3"
# Initialize and read in the indices for each field
FLOWCELL_INDEX=-1; FACTOR_INDEX=-1; IP_CTRL_INDEX=-1; INPUT_CTRL_INDEX=-1
HEADER=$(head -n 1 ${METADATA} | tr '[:upper:]' '[:lower:]')
IFS=$'\t' read -ra ADDR <<< "$HEADER"
for i in "${!ADDR[@]}"; do
	# If index denotes field, change the index. Cut is 1-indexed, add 1
	if [[ ${ADDR[$i]} = 'name' ]] ; then
		FACTOR_INDEX=$((i+1))
	elif [[ ${ADDR[$i]} = 'experiment name' ]] || [[ ${ADDR[$i]} = 'sequencing core project' ]] ; then
		FLOWCELL_INDEX=$((i+1))
	elif [[ ${ADDR[$i]} = 'ip control' ]] ; then
		IP_CTRL_INDEX=$((i+1))
	elif [[ ${ADDR[$i]} = 'control' ]] || [[ ${ADDR[$i]} = 'input control' ]] ; then
		INPUT_CTRL_INDEX=$((i+1)) 
	fi
done
# Add 2 to skip 0th line and 1st line which is header
LINE_NUM=$((SLURM_ARRAY_TASK_ID+2))
FILE_LINE=$(sed -n "${LINE_NUM}p" ${METADATA})
FLOWCELL=$(echo "$FILE_LINE" | cut -f${FLOWCELL_INDEX})
FACTOR=$(echo "$FILE_LINE" | cut -f${FACTOR_INDEX})
FACTOR_FILE=$(/bin/ls -1 ${IN_DIR}/${FACTOR}*.bam.bai | sed "s/.bai//")
IP_CTRL=$(echo "$FILE_LINE" | cut -f${IP_CTRL_INDEX})
INPUT_CTRL=$(echo "$FILE_LINE" | cut -f${INPUT_CTRL_INDEX})
IP_CTRL_FILE=$(/bin/ls -1 ${IN_DIR}/${IP_CTRL}*bam)
INPUT_CTRL_FILE=$(/bin/ls -1 ${IN_DIR}/${INPUT_CTRL}*bam)
echo "Factor is: ${FACTOR}, file is: ${FACTOR_FILE}"
echo "Flowcell is: ${FLOWCELL}, IP control is: ${IP_CTRL}, Input control is: ${INPUT_CTRL}"

# Write sample metadata to file with name, timestamp and
# additional information
METADATA_FILE="${OUT_DIR}/${FACTOR}_metadata.txt"
TIMESTAMP=$(stat -c%z ${METADATA} | cut -d' ' -f1)
HEADER="Factor\tFlowcell\tIp_control\tInput_control\tTimestamp"
echo -e ${HEADER} > ${METADATA_FILE}
echo -e "${FACTOR}\t${FLOWCELL}\t${IP_CTRL}\t${INPUT_CTRL}\t${TIMESTAMP}" >> ${METADATA_FILE} 

# Case where sample has both controls
if [ -n "${IP_CTRL}" ] && [ -n "${INPUT_CTRL}" ];
then
	echo "Sample, ${FACTOR_FILE}, has IP control ${IP_CTRL} and \
	input control ${INPUT_CTRL}"
	echo "Sample has both Input and IP controls, ${INPUT_CTRL_FILE} and ${IP_CTRL_FILE}"
	plotFingerprint -b ${FACTOR_FILE} ${INPUT_CTRL_FILE} ${IP_CTRL_FILE} \
	--labels ${FACTOR} ${INPUT_CTRL} ${IP_CTRL} \
	--outQualityMetrics ${OUT_DIR}/${FACTOR}_QCmetrics.txt \
	--JSDsample ${INPUT_CTRL} \
	-T "Fingerprint of ${FACTPR}" \
	-plot ${OUT_DIR}/${FACTOR}.png \
	--outRawCounts ${OUT_DIR}/${FACTOR}_counts.tab
# Case where sample has w/ IP control and no Input control
elif [ -n "${IP_CTRL}" ] && [ -z "${INPUT_CTRL}" ];
then
	echo "Sample, ${FACTOR_FILE}, has IP control ${IP_CTRL}"
        plotFingerprint -b ${FACTOR_FILE} ${IP_CTRL_FILE} \
        --labels ${FACTOR} ${IP_CTRL} \
        --outQualityMetrics ${OUT_DIR}/${FACTOR}_QCmetrics.txt \
        --JSDsample ${IP_CTRL} \
        -T "Fingerprint of ${FACTOR}" \
        -plot ${OUT_DIR}/${FACTOR}.png \
        --outRawCounts ${OUT_DIR}/${FACTOR}_counts.tab
# Case where sample has w/ Input control and no IP control
elif [ -z "${IP_CTRL}" ] && [ -n "${INPUT_CTRL}" ];
then
	echo "Sample, ${FACTOR_FILE}, has Input control ${INPUT_CTRL}"
        plotFingerprint -b ${FACTOR_FILE} ${INPUT_CTRL_FILE} \
        --labels ${FACTOR} ${INPUT_CTRL} \
        --outQualityMetrics ${OUT_DIR}/${FACTOR}_QCmetrics.txt \
        --JSDsample ${INPUT_CTRL} \
        -T "Fingerprint of ${FACTOR}" \
        -plot ${OUT_DIR}/${FACTOR}.png \
        --outRawCounts ${OUT_DIR}/${FACTOR}_counts.tab
# Case where sample has no control
else
	echo "Sample, ${FACTOR_FILE}, has no controls"
        plotFingerprint -b ${FACTOR_FILE} \
        --labels ${FACTOR} \
        --outQualityMetrics ${OUT_DIR}/${FACTOR}_QCmetrics.txt \
        -T "Fingerprint of ${FACTOR}" \
        -plot ${OUT_DIR}/${FACTOR}.png \
        --outRawCounts ${OUT_DIR}/${FACTOR}_counts.tab
fi

exit 0
