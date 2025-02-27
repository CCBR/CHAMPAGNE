#!/usr/bin/env python
"""
doi: 10.1126/science.aav1898
pgs. 6-7 of the supplement

https://github.com/CCBR/CHAMPAGNE/issues/159
"""
import sys


def main(
    infilename,
    outfilename,
    chrom_sizes_fname="/data/CCBR_Pipeliner/db/PipeDB/Indices//hg38_basic/indexes/hg38.fa.sizes",
    peak_width=500,
):
    with open(chrom_sizes_fname, "r") as chrom_sizes_file:
        chrom_sizes = {
            line.strip().split("\t")[0]: int(line.strip().split("\t")[1])
            for line in chrom_sizes_file
        }

    # create fixed width peaks centered on summits
    with open(infilename, "r") as infile:
        peaks = {
            Peak.from_line(line).to_fixed_width(peak_width, chrom_sizes)
            for line in infile
        }

    # iterative removal method, keeping most significant peak out of set of overlapping peaks
    consensus_peaks = set()
    while peaks:
        curr_peak = max(peaks, key=lambda peak: peak.qvalue)
        consensus_peaks.add(curr_peak)
        peaks = {peak for peak in peaks if not peak.overlaps(curr_peak)}
    with open(outfilename, "w") as outfile:
        outfile.writelines([peak.to_bed for peak in consensus_peaks])


class Peak:
    def __init__(
        self,
        chrom,
        start,
        end,
        name,
        score,
        strand,
        signalvalue,
        pvalue,
        qvalue,
        summit,
    ):
        self.chrom = chrom
        self.start = start
        self.end = end
        self.name = name
        self.score = score
        self.strand = strand
        self.signalvalue = signalvalue
        self.pvalue = pvalue
        self.qvalue = qvalue
        self.summit = summit

    def __eq__(self, other):
        return (
            self.chrom == other.chrom
            and self.start == other.start
            and self.end == other.end
            and self.name == other.name
            and self.score == other.score
            and self.strand == other.strand
            and self.signalvalue == other.signalvalue
            and self.pvalue == other.pvalue
            and self.qvalue == other.qvalue
            and self.summit == other.summit
        )

    def __hash__(self):
        return hash(
            (
                self.chrom,
                self.start,
                self.end,
                self.name,
                self.score,
                self.strand,
                self.signalvalue,
                self.pvalue,
                self.qvalue,
                self.summit,
            )
        )

    @classmethod
    def from_line(cls, line):
        fields = line.strip().split("\t")
        return cls(
            fields[0],
            int(fields[1]),
            int(fields[2]),
            fields[3],
            float(fields[4]),
            fields[5],
            float(fields[6]),
            float(fields[7]),
            float(fields[8]),
            int(fields[9]),
        )

    def to_fixed_width(self, fixed_width, chrom_sizes):
        # trim ends that overlap chromosome ends
        start = max(0, self.summit - fixed_width // 2)
        end = min(chrom_sizes[self.chrom], start + fixed_width)
        assert (end - start) <= fixed_width
        return Peak(
            self.chrom,
            start,
            end,
            self.name,
            self.score,
            self.strand,
            self.signalvalue,
            self.pvalue,
            self.qvalue,
            self.summit,
        )

    def overlaps(self, other):
        return (
            self.chrom == other.chrom
            and self.start <= other.end
            and self.end >= other.start
        )

    @property
    def to_bed(self):
        return f"{self.chrom}\t{self.start}\t{self.end}\t{self.name}\t{self.score}\t{self.strand}\t{self.signalvalue}\t{self.pvalue}\t{self.qvalue}\t{self.summit}\n"


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
