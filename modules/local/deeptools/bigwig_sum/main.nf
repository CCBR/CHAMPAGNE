process BIGWIG_SUM {
    label 'qc'
    label 'deeptools'
    label 'process_high_memory'

    container "${params.containers_deeptools}"

    input:
        path(bigwigs)

    output:
        path("bigWigSum.npz"), emit: array

    script:
    // sort files on basenames, otherwise uses full file path
    """
    multiBigwigSummary bins \\
      -b ${bigwigs.sort({ a, b -> a.baseName <=> b.baseName }).join(' ')} \\
      --smartLabels \\
      -o bigWigSum.npz
    """

    stub:
    """
    echo "${bigwigs}" > bigWigSum.npz
    """
}
