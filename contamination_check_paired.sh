#!/bin/bash
#SBATCH --partition=new,all
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=djy3@duke.edu
#SBATCH --output=/data/reddylab/Darryl/logs/contamination_check.out

# Reads a 2 fastq files and takes a subsample of 100K paired reads and aligns them for contamination checks.

# Load dependencies and declare parameters
module load bowtie2
in_file_one="$1"
in_file_two="$2"
script_path="/data/reddylab/Darryl/bin/subsample_paired_reads.sh"

cd /data/reddylab/Darryl/Genomes
mkdir -p /data/reddylab/Darryl/misc
# Create a temporary file for the read subsample
bash ${script_path} ${in_file_one} ${in_file_two} 100000 "tmp.fastq"
echo ${in_file_one} ${in_file_two}
echo "Of 100,000 reads:" 2>&1
echo "E. Coli check: " 2>&1
# ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
bowtie2 -x e_coli -U "tmp.fastq" 2>&1 >/dev/null | grep "exactly 1 time"
echo "Yeast check: "
# ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.fna.gz
bowtie2 -x s_cerevisiae -U "tmp.fastq" 2>&1 >/dev/null | grep "exactly 1 time"
echo "Mycoplasma check: "
# ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/345/GCF_000027345.1_ASM2734v1/GCF_000027345.1_ASM2734v1_genomic.fna.gz
bowtie2 -x mycoplasma -U "tmp.fastq" 2>&1 >/dev/null | grep "exactly 1 time"

# Delete file after all alignments have finished
rm tmp.fastq
