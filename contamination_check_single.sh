#!/bin/bash
#SBATCH --partition=new,all
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=djy3@duke.edu
#SBATCH --output=/data/reddylab/Darryl/logs/contamination_check.out

# Reads a fastq file and takes a subsample of 100K unpaired reads and aligns them for contamination checks.

# Load dependencies and declare parameters
module load bowtie2
SAMPLES=( $1 )
SAMPLE=${FILES[${SLURM_ARRAY_TASK_ID}]}
READS_DIR=$2
in_file=$(/bin/ls -1 "${READS_DIR}/${SAMPLE}*.fastq")
out_file="$3"
script_path="/data/reddylab/Darryl/bin/subsample_unpaired_reads.sh"

cd /data/reddylab/Darryl/Genomes
mkdir -p /data/reddylab/Darryl/misc
# Create a temporary file for the read subsample
bash ${script_path} ${in_file} 100000 "tmp.fastq"
# ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
e_coli=$(bowtie2 -x e_coli -U "tmp.fastq" 2>&1 >/dev/null | grep "exactly 1 time" | sed -e 's/^[ \t]*//;s/[ \t]*$//;' | tr -d '()' | cut -d ' ' -f2)
# ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.fna.gz
yeast=$(bowtie2 -x s_cerevisiae -U "tmp.fastq" 2>&1 >/dev/null | grep "exactly 1 time" | sed -e 's/^[ \t]*//;s/[ \t]*$//;' | tr -d '()' | cut -d ' ' -f2)
# ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/345/GCF_000027345.1_ASM2734v1/GCF_000027345.1_ASM2734v1_genomic.fna.gz
myco=$(bowtie2 -x mycoplasma -U "tmp.fastq" 2>&1 >/dev/null | grep "exactly 1 time" | sed -e 's/^[ \t]*//;s/[ \t]*$//;' | tr -d '()' | cut -d ' ' -f2)

# Append data output to specified file
echo "${in_file##*/} ${e_coli%[%]} ${yeast%[%]} ${myco%[%]}" >> $2

# Delete file after all alignments have finished
rm tmp.fastq
