#!/usr/bin/env python
"""
adapted from https://github.com/CCBR/ASPEN/blob/55f909d76500c3502c1c397ef3000908649b0284/workflow/scripts/ccbr_get_consensus_peaks.py
"""

import argparse
import os
import sys
import uuid

import pandas

parser = argparse.ArgumentParser(
    description="""
Get consensus peaks from multiple narrowPeak files
This is similar to the consensus MAX peaks from https://dx.doi.org/10.5936%2Fcsbj.201401002
""",
    formatter_class=argparse.RawTextHelpFormatter,
)
parser.add_argument(
    "--peakfiles", required=True, nargs="+", help="space separated list of peakfiles"
)
parser.add_argument(
    "--outbed", required=True, dest="outbed", help="consensus output bed file"
)
parser.add_argument(
    "--filter",
    required=False,
    default=0.5,
    dest="filter",
    help="min. fraction of replicates that should be represented in each peak ",
)
parser.add_argument(
    "--nofilter",
    action="store_true",
    default="store_false",
    required=False,
    dest="nofilter",
    help=" do not filter keep all peaks with score",
)


deleteFiles = []

args = parser.parse_args()
print(args)


filter = float(args.filter)

rand_name = str(uuid.uuid4())

# concat
cmd = "cat"
for p in args.peakfiles:
    cmd += " " + p
cmd += " | cut -f1-3 > " + rand_name + ".concat.bed"

deleteFiles.append(rand_name + ".concat.bed")
print(cmd)
os.system(cmd)

# sort and merge
cmd = (
    "bedSort "
    + rand_name
    + ".concat.bed "
    + rand_name
    + ".concat.bed && bedtools merge -i "
    + rand_name
    + ".concat.bed > "
    + rand_name
    + ".merged.bed"
)

deleteFiles.append(rand_name + ".merged.bed")
print(cmd)
os.system(cmd)

# check merged count
with open(rand_name + ".merged.bed") as merged_file:
    npeaks = len(merged_file.readlines())
if npeaks == 0:
    sys.exit("Number of merged peaks = 0")


for count, p in enumerate(args.peakfiles, start=1):
    sortedfile = p + ".sorted." + rand_name
    countfile = p + ".counts." + rand_name
    cmd = (
        "cut -f1-3 "
        + p
        + " > "
        + sortedfile
        + " && bedSort "
        + sortedfile
        + " "
        + sortedfile
    )
    print(cmd)
    os.system(cmd)
    cmd = (
        "bedmap --delim '\t' --echo-ref-name --count "
        + rand_name
        + ".merged.bed "
        + sortedfile
        + "|awk -F'\t' -v OFS='\t' '{if ($2>1){$2=1}{print}}' > "
        + countfile
    )
    print(cmd)
    os.system(cmd)
    deleteFiles.append(countfile)
    deleteFiles.append(sortedfile)
    if count == 1:
        df = pandas.read_csv(countfile, delimiter="\t")
        df.columns = ["peakid", countfile]
    else:
        dfx = pandas.read_csv(countfile, delimiter="\t")
        dfx.columns = ["peakid", countfile]
        df = df.merge(dfx, on="peakid")

df = df.set_index("peakid")
df = df.sum(axis=1) / len(df.columns)
df = pandas.DataFrame({"peakid": df.index, "score": df.values})


with open(args.outbed, "w") as out:
    for _index, row in df.iterrows():
        chrom, coords = row["peakid"].split(":")
        start, end = coords.split("-")
        score = float(row["score"])
        if args.nofilter or score > filter:
            out.write(
                f"{chrom}\t{start}\t{end}\t{row['peakid']}\t{score:.3f}\t.\tNA\tNA\tNA\n"
            )

for f in deleteFiles:
    os.remove(f)
