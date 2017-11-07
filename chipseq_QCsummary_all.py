import os, csv
import argparse
import pandas as pd
import base64
import csv_to_mongo
import subprocess

# Python script and command line tool for compiling fingerprint and QC data from ChIP-seq
# experiments. Make sure to activate the 'alex' virtual environment from miniconda using
# `source /data/reddylab/software/miniconda2/bin/activate alex` command from HARDAC. To
# run full workflow, run the `countFactors_standard.sh` that outputs data directories
# then run this script on those outputs.


CWD = os.getcwd() + "/"
OUT_DIR = CWD + "QC_summary/"
CLIENT_URI="mongodb://67.159.92.22:2017/chipseq_qc"


def pretty_print(df):
    with pd.option_context('display.max_rows', None, 'display.max_columns', len(df)):
        print(df)


def stringFormat(string):
    return string.strip().lower().replace(" ", "_").replace('-', '_').replace("%", "percent")


def read_file_base64(in_file):
    """
    Helper function that reads file into binary
    :param in_file: Absolute path to file
    :return: The file contents as a string
    """
    try:
        with open(in_file, 'rb') as f:
            return base64.b64encode(f.read())
    # Exception for symlinks
    except IOError:
        with open(os.readlink(in_file), 'rb') as f:
            return base64.b64encode(f.read())


def read_metadata(in_file):
    """
    Helper function that reads a metadata file and returns a dictionary of values
    :param in_file: The full metadata file path as a string
    :return: A dictionary of the files' attributes
    """
    attr = {}
    # Read a 2-line tab-delimited file with header and contents
    with open(in_file, 'rb') as f:
        reader = csv.reader(f, delimiter='\t')
        header = [stringFormat(ele) for ele in next(reader)]
        contents = [stringFormat(ele) for ele in next(reader)]
        attr = dict(zip(header, contents))

    return attr


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
    elements = []
    useColumns = []
    for i, ele in enumerate(arr):
        if ele.lower() in header_dict.keys():
            elements.append(header_dict[ele.lower()])
            useColumns.append(i)
    return elements, useColumns


def process_directory(in_dir):
    """
    Processes data in directory, returns as Pandas dataframe
    :param in_dir: Input data directory, String
    :return: A Pandas dataframe containing fingerprint data, QCs, and images
    """
    qc_file = ""
    fingerprint_qc_arr = []
    spp_data_arr = []
    images = []
    metadata_files = []
    # Separate files into appropriate lists
    for filename in os.listdir(in_dir):
        # Append the file path
        file_path = os.path.join(in_dir, filename)
        if filename.lower().endswith('_metadata.txt'):                      # Find metadata
            metadata_files.append(file_path)
        elif filename.endswith('_QCmetrics.txt'):                           # If fingerprint QC file, add to array
            fingerprint_qc_arr.append(file_path)
        elif filename.lower() == 'qc.csv' or filename.lower() == 'qc.txt' \
                or filename.lower() == 'chip_seq_summary_iter0.tsv':        # If lab-computed QC file, set var
            qc_file = file_path
        elif filename.endswith(".png") or filename.endswith(".pdf"):
            images.append(file_path)
        elif filename.endswith('.cross_corr.txt'):                          # If cross corr data, add to array
            spp_data_arr.append(file_path)

    if not qc_file:
        return None

    # Process QC file into a dataframe
    with open(os.readlink(qc_file), 'rb') as f:
        # Find delimiter using Sniffer class
        dialect = csv.Sniffer().sniff(f.readline(), ['\t', ','])
        reader = csv.reader(f, delimiter=dialect.delimiter)
        f.seek(0)
        column_names = standardize_header(next(reader))
        # Read data into Pandas dataframe
        df = pd.read_csv(f, delimiter=dialect.delimiter, header=None,
                         names=column_names[0], usecols=column_names[1], engine='python')
    df.set_index('sample', inplace=True)

    # Add fingerprint data to dataframe
    fp_df = pd.DataFrame()
    for filename in fingerprint_qc_arr:
        if os.stat(filename).st_size != 0:
            with open(filename, 'rb') as f:
                reader = csv.reader(f, delimiter='\t')
                header = [stringFormat(ele) for ele in next(reader)]
                print("Header for fingerprint is: {}".format(header))
                new_fp_df = pd.read_csv(f, delimiter='\t', header=None,
                                        names=header, engine='python')
                fp_df = fp_df.append(new_fp_df)
    fp_df.drop_duplicates(subset='sample', keep='last', inplace=True)
    fp_df.set_index('sample', inplace=True)
    df = df.merge(fp_df, left_index=True, right_index=True, how='left')

    # Add fingerprint images and metadata information
    for sample in df.index.values:                                  # Index is sample name
        fp_image = ''
        spp_image = ''
        metadata_file = ''
        for filename in images:
            if filename.endswith('.png') and sample in filename:
                fp_image = filename
            elif filename.endswith('.pdf') and sample in filename:
                spp_image = filename
        for filename in metadata_files:
            if sample in filename:
                metadata_file = filename
        if fp_image:
            df.set_value(sample, 'fp_image', read_file_base64(fp_image))
        if spp_image:
            df.set_value(sample, 'spp_image', read_file_base64(spp_image))
        if metadata_file:
            # Read in all metadata attributes into df
            for key, value in read_metadata(metadata_file).iteritems():
                df.set_value(sample, key, value)
        # Set flowcell name to base directory
        df.set_value(sample, 'flowcell', os.path.basename(in_dir))

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

    # if argument specifies JSON
    if args.json:
        filename = args.out + 'chipseq_QCsummary.json'
        df.to_json(args.out + 'chipseq_QCsummary.json', orient='index')
        print("Wrote JSON file to: " + args.out)
    # if argument specifies TSV
    if args.tsv:
        filename = os.path.join(args.out, 'chipseq_QCsummary.tsv')
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

    print("--Program finished successfully--")
    return 0

if __name__ == '__main__':
    main()
