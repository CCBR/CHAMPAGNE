process COMPUTE_MATRIX {
  tag { meta.id }
  label 'qc'
  label 'deeptools'
  label 'process_high'

  container "${params.containers_deeptools}"

  input:
    tuple val(meta), path(bigwigs), path(bed), val(mattype)

  output:
    path("*.mat.gz"), emit: mat

  script:
  def cmd = null
  def args = null
  if (mattype == 'TSS') {
    cmd = 'reference-point'
    args = ['--referencePoint TSS',
            '--upstream 3000',
            '--downstream 3000'
            ].join(' ').trim()

  } else if (mattype == 'metagene') {
    cmd = 'scale-regions'
    args = ['--upstream 1000',
            '--regionBodyLength 2000',
            '--downstream 1000'
            ].join(' ').trim()
  } else {
    error "Invalid matrix type: ${mattype}"
  }
  """
  computeMatrix ${cmd} \\
    -S ${bigwigs.sort({ a, b -> a.baseName <=> b.baseName }).join(' ')} \\
    -R ${bed} \\
    -p ${task.cpus} \\
    -o ${meta.id}.${bed.baseName}.${mattype}.mat.gz \\
    --skipZeros \\
    --smartLabels \\
    ${args}
  """

  stub:
  """
  touch ${meta.id}.${bed.baseName}.${mattype}.mat.gz
  """
}
