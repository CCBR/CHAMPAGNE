process SICER {
    tag { meta.id }
    label 'peaks'
    label 'process_high'

    container "${params.containers_sicer}"

    input:
        tuple val(meta), path(chip), path(input), val(fraglen), val(genome_frac)

    output:
        tuple val(meta), path("*islands-summary"), val("${task.process.tokenize(':')[-1].toLowerCase()}"), emit: peak
        tuple path("*island.bed"), path("*.scoreisland"), path("*normalized.wig"),                         emit: sicer

    script:
    """
    sicer \\
      -t ${chip} \\
      -c ${input} \\
      -s ${params.sicer_species} \\
      -rt 100 \\
      -w 300 \\
      -f ${fraglen} \\
      -egf ${genome_frac} \\
      -g 600 \\
      -fdr 1E-2 \\
      -cpu ${task.cpus}
    """

    stub:
    """
    for ext in scoreisland normalized.wig islands-summary island.bed; do
        touch ${chip.baseName}.\${ext}
    done
    """
}
