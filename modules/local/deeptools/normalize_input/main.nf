process NORMALIZE_INPUT {
  label 'qc'
  label 'deeptools'
  label 'process_high'

  container "${params.containers_deeptools}"

  input:
    tuple val(meta), path(chip), path(input)

  output:
    tuple val(meta), path("*.inputnorm.bw"), emit: bigwig

  script:
  """
  bigwigCompare \\
  --binSize ${params.deeptools_bin_size} \\
  --outFileName ${meta.id}.inputnorm.bw \\
  --outFileFormat 'bigwig' \\
  --bigwig1 ${chip} \\
  --bigwig2 ${input} \\
  --operation 'subtract' \\
  --skipNonCoveredRegions \\
  --numberOfProcessors ${task.cpus}
  """

  stub:
  """
  touch ${meta.id}.inputnorm.bw
  """
}
