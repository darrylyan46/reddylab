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

def makeFingerprintSummary(in_dir, out_dir):
    """Creates summary of fingerprint data in a tab-delimited format"""
    files = [os.path.join(in_dir, file) for file in os.listdir(in_dir) if file.endswith('QCmetrics.txt')]
    assert(len(files) > 0)

    out_file = open(out_dir + 'fingerprint_QCsummary.tsv', 'w+')
    writer = csv.writer(out_file, delimiter='\t')
    with open(files[0], 'rb') as header_file:
        reader = csv.reader(header_file, delimiter='\t')
        writer.writerow(reader.next())                                  #Read in the header

    for file in files:
        if os.stat(file).st_size != 0:
            with open(file, 'rb') as f:
                reader = csv.reader(f, delimiter='\t')
                next(reader)
                for line in reader:
                    if "ctrl" not in line:                              #Skip controls
                        writer.writerow(line)

    out_file.close()
    return 0


def main():
    parser = argparse.ArgumentParser('Generates QC metric summary file for available ChIP-seq samples')
    parser.add_argument('-f', '--fingerprint_dir', required=False, nargs='?',
                        default=FINGERPRINT_PATH, help='Directory for fingerprint data')
    parser.add_argument('-c', '--chilin_dir', required=False, type=str, nargs='?',
                        default=CHILIN_PATH, help='Directory for chilin data')
    parser.add_argument('-o', '--out', required=False, type=str, nargs='?',
                        default=OUT_DIR,
                        help='Output directory name (by default called QC_summary in current directory)')
    parser.add_argument('-j', '--json', required=False, action='store_true',
                        default=False, help='Output format as .json file (by default False)')
    parser.add_argument('-t', '--tsv', required=False, action='store_true',
                        default=True,
                        help='Output format as .tsv file (by default True)')
    args = parser.parse_args()

    if not os.path.isdir(args.out):
        os.makedirs(args.out)
    else:
        write_check = raw_input("Directory: 'QC_summary', already exists, write in directory anyways? [y/n]: ")
        if write_check == "y":
            pass
        elif write_check == "n":
            return
        else:
            raise ValueError("Invalid answer: '%s'" % write_check)

    makeFingerprintSummary(args.fingerprint_dir, args.out)
    fingerprint_df = pd.read_csv(FINGERPRINT_SUMMARY_PATH, delimiter='\t')
    sum_df = pd.read_csv(SUMMARY_PATH, delimiter='\t')
    sum_df.rename(columns={'sample':'Sample'}, inplace=True)
    print(fingerprint_df)
    print(sum_df)
    result = pd.merge(fingerprint_df, sum_df, on='Sample')
    result.set_index('Sample', inplace=True)
    #if argument specifies JSON
    if args.json:
        result.to_json(args.out + 'chipseq_QCsummary.json', orient='index')
        print("Wrote JSON file to: " + args.out)
    #if argument specifies TSV
    if args.tsv:
        result.to_csv(args.out + 'chipseq_QCsummary.tsv', sep='\t')
        print("Wrote TSV file to: " + args.out)
    print("--Program finished successfully--")

if __name__ == '__main__':
    main()
