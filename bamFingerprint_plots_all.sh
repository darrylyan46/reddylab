#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=outlogs/myout_%a.out
source /data/reddylab/software/miniconda2/bin/activate alex
CTRL_FILE=/data/reddylab/projects/GGR/data/chip_seq/metadata/trt_to_ctrl.txt
OUT_DIR=/data/reddylab/Darryl/plots
MY_DIR=/data/reddylab/projects/GGR/data/chip_seq/mapped_reads/iter0
FACTORS=( $1 )
FACTOR=${FACTORS[${SLURM_ARRAY_TASK_ID}]}
ctrls=$(grep "${FACTOR}_" ${CTRL_FILE} | grep -v nan | cut -f2 )
factors=$(/bin/ls -1 ${MY_DIR}/${FACTOR}_*bam | sed "s@${MY_DIR}/@@" | cut -d '.' -f1,2)
labels=(${ctrls[@]} ${factors[@]})
declare -a data
for i in ${labels[@]}; do
	data+=($(/bin/ls -1 ${MY_DIR}/${i}.*bam))
done
echo "The factor is: ${FACTOR}"
echo "Replicates are: ${labels[@]} with ${#labels[@]} labels"
echo "Files are: ${data[@]} with ${#data[@]} files"
plotFingerprint -b ${data[@]} \
	--labels ${labels[@]} \
	-T "Fingerprints of ${FACTOR}" \
	-plot ${OUT_DIR}/${FACTOR}.png \
	--outRawCounts ${OUT_DIR}/${FACTOR}_counts.out	
