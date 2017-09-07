#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=count_no_ctrl.out
source /data/reddylab/software/miniconda2/bin/activate alex
DIR="$1"
OUT_DIR="$2"
mkdir -p ${OUT_DIR}
rsync -v ${DIR}/*spp* ${OUT_DIR}
cp -v ${DIR}/qc.txt ${OUT_DIR}
FACTORS=($(/bin/ls -1 ${DIR}/*bam.bai | sed "s@${DIR}/@@" | cut -d '.' -f1,2,3,4,5 | grep -v gre | uniq))
len=$((${#FACTORS[@]}-1))
echo "The directory is ${DIR}"
echo "The files are ${FACTORS[@]}"
echo "There are ${#FACTORS[@]} files"
sbatch --array=0-${len}%50 /data/reddylab/Darryl/GitHub/reddylab/bamFingerprint_plots_no_ctrl.sh ${DIR} "$(echo ${FACTORS[@]})" ${OUT_DIR}
