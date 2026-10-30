process SPLIT_REF_CHROMS {
    tag { fasta }
    label 'process_single'
    container "${params.containers_base}"

    input:
        path(fasta)

    output:
        path("${fasta.baseName}.chrom.sizes"), emit: chrom_sizes
        path("chroms/")                      , emit: chrom_dir

    script:
    """
    splitRef.py ${fasta} ${fasta.baseName}.chrom.sizes chroms
    """
    stub:
    """
    touch ${fasta.baseName}.chrom.sizes
    mkdir -p chroms/
    touch chroms/chr1.fa
    """
}
