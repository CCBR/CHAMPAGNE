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
        chrom_lengths[chrom] for chrom in chrom_lengths if "_" not in chrom
    )
    chrom_len_sum = 0
    for chrom in chrom_lengths:
        if "_" not in chrom:
            chrom_len_sum += chrom_lengths[chrom]

    frac = effective_genome_size / chrom_len_sum
    if not (0 < frac <= 1):
        raise ValueError(f"Effective genome fraction ({frac}) is not between 0 and 1.")
    return frac


def test():
    chrom_sizes = """chr1	248956422
chr2	242193529
chr3	198295559
chr4	190214555
chr5	181538259
chr6	170805979
chr7	159345973
chr8	145138636
chr9	138394717
chr10	133797422
chr11	135086622
chr12	133275309
chr13	114364328
chr14	107043718
chr15	101991189
chr16	90338345
chr17	83257441
chr18	80373285
chr19	58617616
chr20	64444167
chr21	46709983
chr22	50818468
chr_X	156040895
chr_Y	57227415
chr_M	16569""".split("\n")
    effective_genome_size = 2700000000

    assert calc_egf(effective_genome_size, chrom_sizes) == 0.9391299376153861


if __name__ == "__main__":
    main(sys.argv)
