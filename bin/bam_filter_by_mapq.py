#!/usr/bin/env python

"""
source https://github.com/CCBR/Pipeliner/blob/86c6ccaa3d58381a0ffd696bbf9c047e4f991f9e/Results-template/Scripts/bam_filter_by_mapq.py
"""

import pysam
import argparse

parser = argparse.ArgumentParser(description="filter PE bamfile by mapQ values")
parser.add_argument("-i", dest="inBam", required=True, help="Input Bam File")
parser.add_argument("-o", dest="outBam", required=True, help="Output Bam File")
parser.add_argument(
    "-q",
    dest="mapQ",
    type=int,
    required=False,
    help="mapQ value ... default 6",
    default=6,
)
args = parser.parse_args()
samfile = pysam.AlignmentFile(args.inBam, "rb")
mapq = dict()
for read in samfile.fetch():
    if read.is_unmapped:
        continue
    if read.is_supplementary:
        continue
    if read.is_secondary:
        continue
    if read.is_duplicate:
        continue
    if read.is_proper_pair:
        if read.mapping_quality < args.mapQ and read.query_name in mapq:
            del mapq[read.query_name]
        if read.mapping_quality >= args.mapQ and read.query_name not in mapq:
            mapq[read.query_name] = 1
samfile.close()
samfile = pysam.AlignmentFile(args.inBam, "rb")
pairedreads = pysam.AlignmentFile(args.outBam, "wb", template=samfile)
for read in samfile.fetch():
    if read.query_name in mapq:
        if read.is_supplementary:
            continue
        if read.is_secondary:
            continue
        if read.is_duplicate:
            continue
        pairedreads.write(read)
samfile.close()
pairedreads.close()
