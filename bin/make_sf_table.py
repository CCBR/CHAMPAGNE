#!/usr/bin/env python3
"""
Create table of spike-in scaling factors and read counts

Usage:
    python make_sf_table.py scaling_factors.tsv <ids> <counts> [<outfilename>]

Example:
    python make_sf_table.py "id1,id2,id3" "100,200,300" spike_sf.tsv
"""
import sys


def main(infilename, ids, counts, outfilename="spike_sf.tsv"):
    data = dict()
    with open(infilename, "r") as infile:
        header = next(infile)
        for line in infile:
            sample, scaling_factor = line.strip().split("\t")
            data[sample] = [scaling_factor]

    for sample, count in zip(ids.split(","), counts.split(",")):
        data[sample].append(count)

    with open(outfilename, "w") as out_file:
        out_file.write("sample\tscaling_factor\tn_spikein_reads\n")
        for sample, values in data.items():
            out_file.write("\t".join([sample, *values]) + "\n")


if __name__ == "__main__":
    main(*sys.argv[1:])
