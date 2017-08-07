#!/bin/bash
#SBATCH --partition=new
#SBATCH --output=outlogs/chilin.out
#SBATCH --mail-user=darryl.yan@duke.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --mem=12000
source /data/reddylab/software/miniconda2/bin/activate alex
export PATH=$PATH:/data/reddylab/software/ImageMagick/bin
export PATH=$PATH:/data/reddylab/software/bin
export PATH=$PATH:/data/reddylab/software/bedtools2/bin
export PATH=$PATH:/data/reddylab/Alex/bin/chilin/software/mdseqpos/bin
export PATH=$PATH:/data/reddylab/software/seqtk
export PATH=$PATH:/data/reddylab/software/bwa-0.7.13
export PATH=$PATH:/data/common/texlive2017/bin/x86_64-linux
module load fastqc
module load R
DIR=/data/reddylab/projects/GGR/data/chip_seq/processed_raw_reads/iter0
CTRL_MAP=/data/reddylab/projects/GGR/data/chip_seq/metadata/trt_to_ctrl.txt
#ALL_FACTORS=( $1 )
#FACTOR=${ALL_FACTORS[${SLURM_ARRAY_TASK_ID}]}
#factors=($(/bin/ls -1 ${DIR}/${FACTOR}*gz))
#ctrls=($(grep "${FACTOR}_" ${CTRL_MAP} | grep -v nan | cut -f2 ))
#echo "Factors are: ${factors[@]}"
#echo "Controls are: ${ctrls[@]}"
#echo "There are ${#factors[@]} factors and ${#ctrls[@]} controls."
sample=$(ls ${DIR}/BCL3.t00_rep1*.gz)
ctrl=$(ls ${DIR}/ctrl_002.t00_rep1*.gz)
echo "Sample is: ${sample}"
echo "Control is: ${ctrl}"
which gcc g++ java make gs convert pdflatex R cython samtools
python /data/reddylab/Alex/bin/chilin/setup.py -l
exit 0
chilin simple -u djy3 -s hg38 --threads 8 -i BCL3_t00 -o BCL3_t00 -t ${sample} -c ${ctrl} --dont_remove -p narrow 2>&1 
