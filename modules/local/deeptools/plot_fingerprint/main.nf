process PLOT_FINGERPRINT {
  label 'qc'
  label 'deeptools'
  label 'process_high'

  container "${params.containers_deeptools}"

  input:
    tuple val(meta), path(bams), path(bais)

  output:
    path("*.pdf")          , emit: pdf
    path("*.mat.txt")      , emit: matrix
    path("*.qcmetrics.txt"), emit: metrics

  script:
  // TODO handle extendReads for single vs paired https://github.com/nf-core/chipseq/blob/51eba00b32885c4d0bec60db3cb0a45eb61e34c5/modules/nf-core/modules/deeptools/plotfingerprint/main.nf
  def prefix = task.ext.prefix ?: "${meta.id}"
  def args = meta.single_end ? '--extendReads 200' : ''
  """
  plotFingerprint \\
    --bamfiles ${bams.join(' ')} \\
    --plotFile ${prefix}.plotFingerprint.plot.pdf \\
    --outRawCounts ${prefix}.plotFingerprint.mat.txt \\
    --outQualityMetrics ${prefix}.plotFingerprint.qcmetrics.txt \\
    --numberOfProcessors ${task.cpus} \\
    --skipZeros \\
    --smartLabels \\
    ${args}
  """

  stub:
  """
  for ext in plot.pdf mat.txt qcmetrics.txt; do
    touch ${meta.id}.plotFingerprint.\$ext
  done
  """

}
