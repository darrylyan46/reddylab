#!/bin/bash
#SBATCH --partition=new,all
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=djy3@duke.edu
#SBATCH --output=/data/reddylab/Darryl/logs/contamination_check.out
in_files=( "$@" )
cd /data/reddylab/Darryl/Genomes
mkdir -p /data/reddylab/Darryl/misc
for in_file in ${in_files[@]}; do
echo ${in_file}
echo "E. Coli check: "
# ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
bowtie2 -x e_coli -U ${in_file} -S /data/reddylab/Darryl/misc/e_coli.sam
echo "Yeast check: "
# ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.fna.gz
bowtie2 -x s_cerevisiae -U ${in_file} -S /data/reddylab/Darryl/misc/yeast.sam
echo "Mycoplasma check: "
# ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/345/GCF_000027345.1_ASM2734v1/GCF_000027345.1_ASM2734v1_genomic.fna.gz
bowtie2 -x mycoplasma -U ${in_file} -S /data/reddylab/Darryl/misc/mycoplasma.sam
done
