process RENAME_FASTA_CONTIGS {
    """
    Convert ensembl to UCSC contig names in a fasta file
    """
    tag { fasta }

    container "${params.containers_base}"

    input:
        path(fasta)
        path(map)

    output:
        path("*_renamed*"), emit: fasta

    script:
    def renamed_fasta= "${fasta.getSimpleName()}_renamed.${fasta.getExtension()}"
    """
    #!/usr/bin/env python

    with open("${map}", "r") as mapfile:
        contig_map = {line.strip().split()[0]: line.strip().split()[1] for line in mapfile}

    with open("${fasta}", "r") as infile:
        with open("${renamed_fasta}", "w") as outfile:
            for line in infile:
                if line.startswith(">"):
                    old_contig = line.strip(">").strip()
                    contig = contig_map[old_contig] if old_contig in contig_map.keys() else old_contig
                    outfile.write(f">{contig}\\n")
                else:
                    outfile.write(line)

    """

    stub:
    def renamed_fasta= "${fasta.getSimpleName()}_renamed.${fasta.getExtension()}"
    """
    touch ${renamed_fasta}
    """
}
