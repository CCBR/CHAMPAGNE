process CALC_GENOME_FRAC {
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

    input:
        path(chrom_sizes)
        val(effective_genome_size)

    output:
        env(genome_frac), emit: genome_frac

    script:
    """
    genome_frac=`calc_effective_genome_fraction.py ${effective_genome_size} ${chrom_sizes}`
    echo \$genome_frac
    """

    stub:
    """
    genome_frac=0.75
    echo \$genome_frac
    """
}
