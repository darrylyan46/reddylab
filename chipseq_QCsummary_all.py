import os, csv
import argparse
import pandas as pd
import re
import base64

# Python script and command line tool for compiling fingerprint and QC data from ChIP-seq
# experiments. Make sure to activate the 'alex' virtual environment from miniconda using
# `source /data/reddylab/software/miniconda2/bin/activate alex` command from HARDAC. To
# run full workflow, run the `countFactors_standard.sh` that outputs data directories
# then run this script on those outputs.


CWD = os.getcwd() + "/"
OUT_DIR = CWD + "QC_summary/"


def stringFormat(string):
    return string.strip().lower().replace(" ", "_").replace('-', '_').replace("%", "percent")


def base64encode(in_file):
    try:
        with open(in_file, 'rb') as f:
            return base64.b64encode(f.read())
    except IOError:
        with open(in_file, 'rb') as f:
            return base64.b64encode(f.read())


def standardize_header(arr):
    """Returns a dataframe header as list, standardized to
    QC naming convention
    :param arr: A list of strings representing header
    :return: Standardized column names, list of strings
    """
    header_dict = {"sample": "sample", "raw": "reads_sequenced",
                   "reads_sequenced": "reads_sequenced", "reads after trimming": "reads_after_trimming",
                   "trimmed": "reads_after_trimming", "mapped": "reads_mapped",
                   "reads_mapped": "reads_mapped", "percentage_unique": "percent_unique",
                   "%reads unique": "percent_unique",
                   "percentage_unique_mapped_and_filtered": "percent_unique_mapped_filtered",
                   "%reads mapped after de-dup & filtering": "percent_unique_mapped_filtered",
                   "reads in peaks": "reads_in_peaks", "in_peaks": "reads_in_peaks",
                   "percent_in_peaks": "percent_in_peaks", "% reads in peaks": "percent_in_peaks",
                   "broadPeak_count": "broad_peak_count", "narrowPeak_count": "narrow_peak_count",
                   "nrf": "nrf", "pbc": "pbc_one", "nsc": "nsc", "rsc": "rsc", "comment": "comment"}
    useCols = []
    elements = []
    for i, ele in enumerate(arr):
        if ele.lower() in header_dict.keys():
            elements.append(header_dict[ele.lower()])
            useCols.append(i)
    return [elements, useCols]

def process_directory(in_dir):
    """
    Processes data in directory, returns as Pandas dataframe
    :param in_dir: Input data directory, String
    :return: A Pandas dataframe containing fingerprint data, QCs, and images
    """
    fingerprint_qc_arr = []
    spp_data_arr = []
    qc_file = ""
    for file in os.listdir(in_dir):
        if file.endswith('QCmetrics.txt'):                          # If fingerprint QC file, add to array
            fingerprint_qc_arr.append(file)
        elif file.lower() == 'qc.csv' or file.lower() == 'qc.txt'\
                or file.lower() == 'chip_seq_summary_iter0.tsv':    # If lab-computed QC file, set var
            qc_file = file
        elif file.endswith('.cross_corr.txt'):                      # If cross corr data, add to array
            spp_data_arr.append(file)
    assert qc_file != "", "qc.txt or qc.csv file not found for directory: " + str(in_dir)

    # Process QC file into a dataframe
    with open(os.path.join(in_dir, qc_file), 'rb') as f:
        sniffer = csv.Sniffer()
        dialect = sniffer.sniff(f.readline(), ['\t', ','])
        reader = csv.reader(f, delimiter=dialect.delimiter)
        f.seek(0)
        column_names = reader.next()
        f.seek(0)
        df = pd.read_csv(f, delimiter=dialect.delimiter, skiprows=[0], header=None,
                         usecols=standardize_header(column_names)[1],
                         names=standardize_header(column_names)[0], index_col=0)

    # Add fingerprint data to dataframe
    for file in fingerprint_qc_arr:
        if os.stat(os.path.join(in_dir, file)).st_size != 0:
            with open(os.path.join(in_dir, file), 'rb') as f:
                sniffer = csv.Sniffer()
                dialect = sniffer.sniff(f.readline(), ['\t', ','])
                reader = csv.reader(f, delimiter=dialect.delimiter)
                f.seek(0)
                header = reader.next()
                for line in reader:
                    for i in range(len(line)):
                        if i != 0:
                            sample_name = line[0]                   # Sample name is always first element of row
                            df.set_value(sample_name, stringFormat(header[i]), stringFormat(line[i]))

    # Add fingerprint images
    for sample in df.index.values:                                  # Index is sample name
        fp_image = ''
        spp_image = ''
        for img_file in os.listdir(in_dir):
            if img_file.endswith('.png') and sample in img_file:
                    fp_image = img_file
            if img_file.endswith('.pdf') and sample in img_file:
                    spp_image = img_file
        if fp_image != '':
            df.set_value(sample, 'fp_image', base64encode(os.path.join(in_dir, fp_image)))
        if spp_image != '':
            df.set_value(sample, 'spp_image', base64encode(os.path.join(in_dir, spp_image)))

    return df


def main():
    # Command line arguments
    parser = argparse.ArgumentParser('Generates QC metric summary file for available ChIP-seq samples')
    parser.add_argument('-i', '--in_dirs', required=True, nargs='+',
                        help='Directory(ies)for fingerprint data')
    parser.add_argument('--force', required=False, action='store_true',
                        default=False, help='''Program runs non-interactively with
                        default settings (output to QC_summary, override existing file)''')
    parser.add_argument('-o', '--out', required=False, type=str, nargs='?',
                        default=OUT_DIR,
                        help='Output directory name (by default called QC_summary in current directory)')
    parser.add_argument('-j', '--json', required=False, action='store_true',
                        default=False, help='Output format as .json file (by default False)')
    parser.add_argument('-t', '--tsv', required=False, action='store_true',
                        default=True,
                        help='Output format as .tsv file (by default True)')
    parser.add_argument('-e', '--excel', required=False, action='store_true',
                        default=False,
                        help='Output format as .xlsx Excel file with highlighting for QC metrics [NOT FUNCTIONAL]')
    parser.add_argument('-a', '--append', required=False, action='store_true',
                        default=False,
                        help='Append mode, appends data to existing file (no duplicates)')
    args = parser.parse_args()

    if os.path.isdir(args.out):
        if not args.force:
            write_check = raw_input("Directory: 'QC_summary', already exists, write in directory anyways? [y/n]: ")
            if write_check == "y":
                pass
            elif write_check == "n":
                print("Program terminated with no files written")
            else:
                raise ValueError("Invalid answer: '%s'" % write_check)
    else:
        os.makedirs(args.out)

    df = pd.DataFrame()
    for i in range(len(args.in_dirs)):
        new_df = process_directory(args.in_dirs[i])
        df = df.append(new_df)
    factor_names = [row.split('.')[0] for row in df.index.values]
    df.rename(columns={'diff._enrichment':'diff_enrichment'}, inplace=True)
    print('Final result dimensions: ' + str(df.shape))
    print("Number of unique factor names: " + str(len(set(factor_names))))
    print("Header is: " + " ".join(list(df)))
    print("Samples are: " + " ".join(df.index.values))

    # if argument specifies JSON
    if args.json:
        filename = args.out + 'chipseq_QCsummary.json'
        df.to_json(args.out + 'chipseq_QCsummary.json', orient='index')
        print("Wrote JSON file to: " + args.out)
    # if argument specifies TSV
    if args.tsv:
        filename = args.out + 'chipseq_QCsummary.tsv'
        if args.force:
            df.to_csv(filename, sep='\t')
        else:
            if os.path.isfile(filename):
                override = raw_input("File exists already, would you like to override existing file? [y/n]: ")
                if override == 'y':
                    df.to_csv(filename, sep='\t')
                elif override == 'n':
                    append = raw_input("Would you like to append to existing file? [y/n]: ")
                    if append == 'y':
                        current_df = pd.read_csv(filename, delimiter='\t')
                        new = pd.concat([current_df, df], ignore_index=True)
                        print("New dimensions: " + str(new.shape))
                        col_order = list(current_df) + [column for column in list(new) if column not in list(current_df)]
                        new = new.reindex(columns=col_order)
                        new.to_csv(filename, sep='\t', index=False)
                else:
                    raise ValueError("Invalid answer: '%s'" % override)
            else:
                df.to_csv(filename, sep='\t')
        print("Wrote TSV file to: " + args.out)
    # if argument specifies EXCEL
    '''
    if args.excel:
        writer = pd.ExcelWriter(args.out + 'chipseq_QCsummary.xlsx', engine='xlsxwriter')
        result.to_excel(writer, sheet_name='summary')
        worksheet = writer.sheets['summary']
    '''

    print("--Program finished successfully--")

if __name__ == '__main__':
    main()
