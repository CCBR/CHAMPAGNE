process MACS_BROAD {
    tag { meta.id }
    label 'peaks'
    label 'process_high'

    container "${params.containers_macs2}"

    input:
        tuple val(meta), path(chip), path(input), val(format), val(fraglen), val(genome_frac), val(effective_genome_size)

    output:
        tuple val(meta), path("${meta.id}_peaks.broadPeak"), val("${task.process.tokenize(':')[-1].toLowerCase()}"), emit: peak
        path("${meta.id}_peaks.xls")
        path("${meta.id}_peaks.gappedPeak")

    script:
    """
    macs2 callpeak \\
      -t ${chip} \\
      -c ${input} \\
      -g ${effective_genome_size} \\
      -n ${meta.id} \\
      --extsize ${fraglen} \\
      --nomodel \\
      -q ${params.macs_broad_q} \\
      --keep-dup='all' \\
      --format ${format} \\
      --broad \\
      --broad-cutoff ${params.macs_broad_cutoff}
    """

    stub:
    """
    for ext in xls broadPeak gappedPeak; do
        touch ${meta.id}_peaks.\${ext}
    done
    """

}
