#!/usr/bin/env python
import gzip
import platform

import Bio.SeqIO


def main():
    count = 0
    for fastq_filename in ["${fastq}"]:
        with gzip.open(fastq_filename, "rt") as file_handle:
            n_seqs = sum(1 for rec in Bio.SeqIO.parse(file_handle, "fastq"))
        count += n_seqs
    with open("${meta.id}.count.txt", "w") as out_file:
        out_file.write(str(count))
    return count


def write_versions():
    with open("versions.yml", "w") as outfile:
        outfile.write('"${task.process}":\\n')
        outfile.write(f'  Python: "{platform.python_version()}"\\n')
        outfile.write(f'  Biopython: "{Bio.__version__}"\\n')


if __name__ == "__main__":
    write_versions()
    main()
