from pymongo import MongoClient
import sys
import json
import argparse


def main():
    parser = argparse.ArgumentParser('Import data from file (.csv, .tsv, .json) to remote MongoDB URI ')
    parser.add_argument('--clienturi', required=True,
                        help='Client URI to make database connection (example, "mongodb://localhost:27017")')
    parser.add_argument('-db', '--database', required=True, type=str,
                        help="Database to connect to (by name)")
    parser.add_argument('-c', '--collection', required=True, type=str,
                        help="Collection to connect to (by name)")
    parser.add_argument('-f', '--datafile', required=True,
                        help="Data file to be imported")
    parser.add_argument('--type', default='csv', type=str, nargs=1, choices=['csv', 'tsv', 'json'],
                        help="The type of data file (json, csv, or tsv)")
    parser.add_argument('--headerline', required=False, default=False, action='store_true',
                        help="If argument is present, will parse the first file line as header (only CSV and TSV)")
    parser.add_argument('--headers', required=False, default=None, nargs='*',
                        help="If argument 'headerline' is false, use these as file headers (only CSV and TSV)")
    parser.add_argument('--drop', action='store_true', help='Drop collection before inserting')

    args = parser.parse_args()

    client = MongoClient(args.clienturi)
    db = client[args.database]

    if args.drop:
        db[args.collection].drop()

    if args.type == 'json':
        with open(args.datafile, 'rb') as f:
            json_data = json.loads(f.read())
            db[args.collection].insert_one(json_data)
        return

    if not args.headerline:
        assert args.headers is not None, "Must provide headers if file does not contain header line"
        headers = args.headers

    with open(args.datafile, 'rb') as f:
        delimiter = ""
        if 'csv' in args.type:
            delimiter = ","
        elif 'tsv' in args.type:
            delimiter = "\t"
        if args.headerline:
            headers = f.readline().split(delimiter)
        for line in f:
            fields = line.split(delimiter)
            db[args.collection].insert_one(dict(zip(headers, fields)))

if __name__ == '__main__':
    main()
    sys.exit(0)
