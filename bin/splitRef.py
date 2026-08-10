#!/usr/bin/env python

import os
import sys


def formatSequencelength(seq, stringlen):
    fseq = ""
    for i in range(len(seq)):
        index = i + 1
        if index % 80 == 0:
            fseq += "{}{}".format(seq[i], "\n")
        else:
            fseq += seq[i]
    return fseq


def parsed(filename):
    fh = open(filename, "r")
    sequence = ""
    chrom = ""
    seqindex = 0
    seqlen = 0
    for line in fh:
        line = line.strip()
        if line.startswith(">") and sequence != "":
            yield chrom, formatSequencelength(sequence, seqlen), len(sequence)
            chrom = line.split(" ")[0]
            sequence = ""
        elif line.startswith(">"):
            chrom = line.split(" ")[0]
        else:
            seqindex += 1
            sequence += line
            if seqindex == 1:
                seqlen = len(line)
    # formatSequencelength(sequence, seqlen)
    yield chrom, formatSequencelength(sequence, seqlen), len(sequence)
    fh.close()


def main(fasta_fn, chrom_sizes_fn, outdir):
    os.mkdir(outdir)
    chromsizesfh = open(chrom_sizes_fn, "w")

    for chrom, seq, chromsize in parsed(fasta_fn):
        chromsizesfh.write("{}\t{}\n".format(chrom.replace(">", ""), chromsize))
        outfilename = os.path.join(outdir, chrom.replace(">", "") + ".fa")
        outfh = open(outfilename, "w")
        print(f"{chrom}\n")
        outfh.write(f"{chrom}\n{seq.rstrip()}\n")
        outfh.close()

    chromsizesfh.close()


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
