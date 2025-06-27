#!/usr/bin/env python3
"""
Compute scaling factors for spike-in normalization

Usage:
    python compute_scaling_factors.py <ids> <counts> [<outfilename>]

Example:
    python compute_scaling_factors.py "id1,id2,id3" "100,200,300" scaling_factors.tsv
"""
import sys


def main(ids, counts, outfilename="scaling_factors.tsv"):
    ids = ids.split(",")
    counts = counts.split(",")
    # Find the smallest count value
    min_value = min(int(count) for count in counts)

    # Compute scaling factors and write results
    with open(outfilename, "w") as out_file:
        out_file.write("sample\tscalingFactor\n")
        for id, count in zip(ids, counts):
            scaling_factor = round(min_value / int(count), 6)
            out_file.write(f"{id}\t{scaling_factor}\n")


if __name__ == "__main__":
    main(*sys.argv[1:])
