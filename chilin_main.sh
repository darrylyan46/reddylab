#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=outlogs/chilin_main.out
source /data/reddylab/software/miniconda2/bin/activate alex
export PATH=$PATH:/data/reddylab/software/ImageMagick/bin
export PATH=$PATH:/data/reddylab/software/bin
export PATH=$PATH:/data/reddylab/software/bedtools2/bin
module load fastqc
export PATH=$PATH:/data/reddylab/Alex/bin/chilin/software/mdseqpos/bin
export PATH=$PATH:/data/reddylab/software/seqtk
export PATH=$PATH:/data/reddylab/software/bwa-0.7.13
DIR=/data/reddylab/projects/GGR/data/chip_seq/processed_raw_reads/iter0
FACTORS=($(/bin/ls -1 ${DIR}/*gz | sed "s@${DIR}/@@" | sed "s/\_rep.*//" | cut -d '.' -f1,2 | grep -v test | uniq))
echo "Factors are: ${FACTORS[@]}"
echo "Number of factors: ${#FACTORS[@]}"
numFactors=$((${#FACTORS[@]}-1))
sbatch --array=0-${numFactors}%50 chilin_all.sh "$(echo ${FACTORS[@]})"
