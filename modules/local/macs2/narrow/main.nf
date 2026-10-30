process MACS_NARROW {
    tag { meta.id }
    label 'peaks'
    label 'process_high'

    container "${params.containers_macs2}"

    input:
        tuple val(meta), path(chip), path(input), val(format), val(fraglen), val(genome_frac), val(effective_genome_size)

    output:
        tuple val(meta), path("${meta.id}_peaks.narrowPeak"), val("${task.process.tokenize(':')[-1].toLowerCase()}"), emit: peak
        tuple val(meta), path("${meta.id}_peaks.xls"), val("${task.process.tokenize(':')[-1].toLowerCase()}"),        emit: xls
        tuple val(meta), path("${meta.id}_summits.bed"), val("${task.process.tokenize(':')[-1].toLowerCase()}"),      emit: summits

    script:
    """
    macs2 callpeak \\
      -t ${chip} \\
      -c ${input} \\
      -g ${effective_genome_size} \\
      -n ${meta.id} \\
      --extsize ${fraglen} \\
      --nomodel \\
      -q ${params.macs_narrow_q} \\
      --keep-dup='all' \\
      --format ${format}
    """

    stub:
    """
    for ext in peaks.xls peaks.narrowPeak summits.bed; do
        touch ${meta.id}_\${ext}
    done
    """
}
