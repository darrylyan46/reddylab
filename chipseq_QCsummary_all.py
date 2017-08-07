import os, csv, fnmatch
import argparse
import pandas as pd
import base64
import json
import numpy as np
import subprocess

CWD = os.getcwd() + "/"
RAW_READS_PATH = "/data/reddylab/projects/GGR/data/chip_seq/processed_raw_reads/iter0"
FINGERPRINT_PATH = "/data/reddylab/Darryl/plots"
SUMMARY_PATH = "/data/reddylab/projects/GGR/analyses/reports/chip_seq/chip_seq_summary_iter0.tsv"
CHILIN_PATH = ""
OUT_DIR = CWD + "QC_summary/"


def extract_factor_names(df):
    factor_names = [row.split('.')[0] for row in df['sample'].tolist()]
    df['factor_name'] = pd.Series(factor_names, index=df.index)
    print("Filtered by factor: " + str(len(set(factor_names))))
    valid_seps = ['-', ]

def stringFormat(string):
    return string.strip().lower().replace(" ", "_").replace('-', '_').replace("%", "percent")

def base64encode(in_file):
    with open(in_file, 'rb') as f:
        return base64.b64encode(f.read())


def make_fingerprint_summary(in_dir, out_dir):
    """
    Writes summary of fingerprint data in a tab-delimited format to file
    :param in_dir: Working directory containing fingerprint data and QCs, string
    :param out_dir: Output directory, string
    :return: None
    """
    files = [os.path.join(in_dir, file) for file in os.listdir(in_dir) if file.endswith('QCmetrics.txt') \
             and os.stat(os.path.join(in_dir, file)).st_size != 0]
    assert (len(files) > 0), 'Must have at least one fingerprint QC metrics file (QCmetrics.txt) file in the directory'

    out_filename = out_dir + 'fingerprint_QCsummary_' + os.path.basename(in_dir) + '.tsv'
    out_file = open(out_filename, 'wb')
    writer = csv.writer(out_file, delimiter=',')
    with open(files[0], 'rb') as header_file:
        reader = csv.reader(header_file, delimiter='\t')
        header = reader.next()
        writer.writerow(header)                                         # Read in the header

    for file in files:
        if os.stat(file).st_size != 0:
            with open(file, 'rb') as f:
                reader = csv.reader(f, delimiter='\t')
                header = reader.next()                                  # Skip header
                for line in reader:
                    if "ctrl" not in line[0]:
                        writer.writerow(line)
    out_file.close()
    return


def standardize_header(df):
    """Returns a dataframe header as list, standardized to
    QC naming convention
    :param df: A Pandas dataframe object
    :return: Standardized column names, list of strings
    """
    col_names_one = ['sample', 'reads_sequenced', 'reads_after_trimming',
                       'reads_mapped', 'percent_unique', 'reads_mapped_filtered',
                       'percent_unique_mapped_filtered', 'reads_in_peaks',
                       'percent_in_peaks', 'broad_peak_count', 'narrow_peak_count',
                       'pbc_one', 'nsc', 'rsc']
    col_names_two = ['sample', 'reads_sequenced', 'reads_after_trimming',
                     'reads_mapped', 'percent_reads_mapped', 'reads_mapped_filtered',
                     'percent_mapped_filtered', 'reads_in_peaks', 'percent_in_peaks',
                     'peaks', 'percent_unique', 'pbc_one', 'nsc', 'rsc', 'comment']

    if 'raw' in list(df):
        return col_names_one
    else:
        return col_names_two

def file_to_df(filename):
    """
    Creates Pandas dataframe object with under_score headers from CSV or TSV
    :param filename: The file to be read into dataframe, string
    :return: A Pandas dataframe
    """
    with open(filename, 'rb') as f:
        sniffer = csv.Sniffer()
        dialect = sniffer.sniff(f.readline(), ['\t', ','])
        f.seek(0)
        reader = csv.reader(f, delimiter=dialect.delimiter)
        col_names = [stringFormat(col)
                     for col in next(reader)]
        f.seek(0)
        df = pd.read_csv(f, delimiter=dialect.delimiter, skiprows=[0], header=None, names=col_names)
    return df

def process_directory(in_dir):
    """

    :param in_dir: Input data directory, String
    :return: A Pandas dataframe containing fingerprint data, QCs, and images
    """
    fingerprint_qc_arr = []
    spp_data_arr = []
    qc_file = ""
    for file in os.listdir(in_dir):
        if file.endswith('QCmetrics.txt'):                          # If fingerprint QC file, add to array
            fingerprint_qc_arr.append(file)
        elif file.lower() == 'qc.csv' or file.lower() == 'qc.txt':  # If lab-computed QC file, set var
            qc_file = file
        elif file.endswith('.cross_corr.txt'):                      # If cross corr data, add to array
            spp_data_arr.append(file)

    # Process QC file into a dataframe
    with open(os.path.join(in_dir, qc_file), 'rb') as f:
        sniffer = csv.Sniffer()
        dialect = sniffer.sniff(f.readline(), ['\t', ','])
        reader = csv.reader(f, delimiter=dialect.delimiter)
        f.seek(0)
        column_names = [stringFormat(col)
                        for col in next(reader)]
        f.seek(0)
        df = pd.read_csv(f, delimiter=dialect.delimiter, header=None,
                           names=standardize_header(column_names), index_col=0)

    # Add fingerprint data to dataframe
    for file in fingerprint_qc_arr:
        if os.stat(file).st_size != 0:
            with open(os.path.join(in_dir, file), 'rb') as f:
                reader = csv.reader(f, delimiter='\t')
                header = reader.next()
                for line in reader:
                    for i in range(len(line)):
                        sample_name = line[0]                       # Sample name is always first element of row
                        df.set_value(sample_name, stringFormat(header[i]), line[i])

    # Add fingerprint images
    for sample in df['sample'].tolist():
        fp_image = ''
        spp_image = ''
        for file in os.listdir(in_dir):
            if file.endswith('.png') and sample in file:
                fp_image = file
            elif file.endswith('.pdf') and sample in file:
                spp_image = file
        df.set_value(sample, 'fp_image', base64encode(os.path.join(in_dir, fp_image)))
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

        '''
        dir = args.in_dirs[i]

        make_fingerprint_summary(dir, args.out)
        fingerprint_summary_name = args.out + 'fingerprint_QCsummary_' + os.path.basename(dir) + '.tsv'
        fingerprint_df = file_to_df(fingerprint_summary_name)

        # Add fingerprint images
        images = []
        for sample in fingerprint_df['sample'].tolist():
            imgs = [file for file in os.listdir(dir) if file.endswith('.png') and sample in file]
            if imgs:
                with open(os.path.join(dir, imgs[0]), 'rb') as f:
                    data = base64.b64encode(f.read())
                    images.append(data)
            else:
                images.append("")
        fingerprint_df['fp_image'] = pd.Series(images, index=fingerprint_df.index)

        sum_df = file_to_df(args.summary[i])
        sum_df.rename(columns=dict(zip(list(sum_df), standardize_header(sum_df))), inplace=True)
        print(sum_df.head())
        print("Summary dimensions: " + str(sum_df.shape))
        print(fingerprint_df.head())
        print("Fingerprint dimensions: " + str(fingerprint_df.shape))
        result = pd.merge(fingerprint_df, sum_df, how='outer', on='sample')
        result.sort_values(by=['sample'], inplace=True)
        print(result.head())
        print("Merge dimensions: " + str(result.shape))
        df = df.append(result, ignore_index=True)
        print('Appended dataframe, new dataframe is: ' + str(df.shape))
        col_order = list(result) + [col for col in list(df) if col not in list(result)]
        df = df.reindex(columns=col_order)
        '''
    factor_names = [row.split('.')[0] for row in df['sample'].tolist()]
    df['factor_name'] = pd.Series(factor_names, index=df.index)
    df.rename(columns={'diff._enrichment':'diff_enrichment'}, inplace=True)
    df.drop_duplicates('sample', inplace=True)
    df.set_index(['sample'], inplace=True)
    print(df.head())
    print('Final result dimensions: ' + str(df.shape))
    print("Number of unique factor names: " + str(len(set(factor_names))))

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
