#!/usr/bin/env python3
"""
Create table of spike-in scaling factors and read counts

Usage:
    python make_sf_table.py scaling_factors.tsv <ids> <antibodies> <counts> [<outfilename>]

Example:
    python make_sf_table.py scaling_factors_1.tsv,scaling_factors_2.tsv id1,id2,id3 ab1,ab2 100,200,300 spike_sf.tsv
"""

from collections import defaultdict
import sys


def main(infilenames, ids, antibodies, counts, outfilename="spike_sf.tsv"):
    data = defaultdict(list)
    for sample, antibody, count in zip(
        ids.split(","), antibodies.split(","), counts.split(",")
    ):
        data[sample].append(antibody)
        data[sample].append(count)

    for infilename in infilenames.split(","):
        with open(infilename, "r") as infile:
            header = next(infile)
            for line in infile:
                sample, scaling_factor = line.strip().split("\t")
                data[sample].append(scaling_factor)

    with open(outfilename, "w") as out_file:
        header = ["sample", "antibody", "n_spikein_reads", "scaling_factor"]
        out_file.write("\t".join(header) + "\n")
        for sample, values in data.items():
            out_file.write("\t".join([sample, *values]) + "\n")


if __name__ == "__main__":
    main(*sys.argv[1:])
