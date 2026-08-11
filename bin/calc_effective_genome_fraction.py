#!/usr/bin/env python3

"""
Usage:
    calc_effective_genome_fraction.py <chrom_sizes_file> <effective_genome_size>

Example:
    calc_effective_genome_fraction.py hg38.fa.sizes 2700000000

Adapted from: https://github.com/CCBR/Pipeliner/blob/86c6ccaa3d58381a0ffd696bbf9c047e4f991f9e/Rules/ChIPseq.snakefile#L69-L83
"""

import sys


def main(args):
    effective_genome_size = int(args[1])
    chrom_sizes_filename = args[2]

    with open(chrom_sizes_filename, "r") as infile:
        chrom_sizes = infile.readlines()

    print(calc_egf(effective_genome_size, chrom_sizes))


def calc_egf(effective_genome_size: int, chrom_sizes_list: list):
    # creates dictionary with { chromosome: length }
    chrom_lengths = {line.split()[0]: int(line.split()[1]) for line in chrom_sizes_list}
    chrom_len_sum = sum(
        length for chrom, length in chrom_lengths.items() if "_" not in chrom
    )

    frac = effective_genome_size / chrom_len_sum
    if not (0 < frac <= 1):
        raise ValueError(f"Effective genome fraction ({frac}) is not between 0 and 1.")
    return frac


def test():
    chrom_sizes = [
        "chr1\t248956422",
        "chr2\t242193529",
        "chr3\t198295559",
        "chr4\t190214555",
        "chr5\t181538259",
        "chr6\t170805979",
        "chr7\t159345973",
        "chr8\t145138636",
        "chr9\t138394717",
        "chr10\t133797422",
        "chr11\t135086622",
        "chr12\t133275309",
        "chr13\t114364328",
        "chr14\t107043718",
        "chr15\t101991189",
        "chr16\t90338345",
        "chr17\t83257441",
        "chr18\t80373285",
        "chr19\t58617616",
        "chr20\t64444167",
        "chr21\t46709983",
        "chr22\t50818468",
        "chr_X\t156040895",
        "chr_Y\t57227415",
        "chr_M\t16569",
    ]
    effective_genome_size = 2700000000

    assert calc_egf(effective_genome_size, chrom_sizes) == 0.9391299376153861


if __name__ == "__main__":
    main(sys.argv)
