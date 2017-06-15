import os, csv, fnmatch
import argparse
import pandas as pd
import subprocess

CWD = os.getcwd() + "/"
RAW_READS_PATH = "/data/reddylab/projects/GGR/data/chip_seq/processed_raw_reads/iter0"
FINGERPRINT_PATH = "/data/reddylab/Darryl/plots"
FINGERPRINT_SUMMARY_PATH = CWD + "QC_summary/" + "fingerprint_QCsummary.tsv"
SUMMARY_PATH = "/data/reddylab/projects/GGR/analyses/reports/chip_seq/chip_seq_summary_iter0.tsv"
CHILIN_PATH = ""
OUT_DIR = CWD + "QC_summary/"

def fingerprintExists(sample):
    '''Returns boolean for if fingerprint data exists for a sample'''
    for roots, dirs, files in os.walk(FINGERPRINT_PATH):
        for file in files:
            if sample in file and file.endswith('QCmetrics.txt'):
                return True
    return False


def main():
    parser = argparse.ArgumentParser('Generates QC metric summary file for available ChIP-seq samples')
    parser.add_argument('-f', '--fingerprint_dir', required=False, default=FINGERPRINT_PATH,
                        help='Directory for fingerprint data')
    parser.add_argument('-c', '--chilin_dir', required=False, default=CHILIN_PATH,
                        help='Directory for chilin data')
    parser.add_argument('-o', '--out', required=False, type=str, default=OUT_DIR,
                        help='Output directory name (by default called QC_summary in current directory)')
    parser.add_argument('-j', '--json', required=False, action='store_true', default=False,
                        help='Output format as .json file (by default False)')
    parser.add_argument('-t', '--tsv', required=False, action='store_true', default=True,
                        help='Output format as .tsv file (by default True)')
    args = parser.parse_args()

    if not os.path.isdir(args.out):
        p = subprocess.Popen(['mkdir', args.out], shell=True)
        p.communicate()

    #Find all factors not in the file -> process those -> add to file

    p = subprocess.Popen(['sbatch', '/data/reddylab/Darryl/fingerprint_summary.sh', args.fingerprin_dir],
                         shell=True,
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate()
    fingerprint_df = pd.read_csv(FINGERPRINT_SUMMARY_PATH, delimiter='\t')
    sum_df = pd.read_csv(SUMMARY_PATH, delimiter='\t')
    result = pd.concat([fingerprint_df, sum_df], axis=1)
    #if argument specifies JSON
    if args.json:
        result.to_json(orient='index')
    #if argument specifies TSV
    if args.tsv:
        result.to_csv('chipseq_QCsummary.tsv', sep='\t')

if __name__ == '__main__':
    main()