process MULTIBAM_SUMMARY {
    label 'process_high'

    container "${params.containers_deeptools}"

    input:
      tuple val(metas), path(bams), path(bais), val(fraglen), path(blacklist_bed)

    output:
      path("*counts.tsv"),         emit: count
      path("*scalingFactors.tsv"), emit: sf

    script:
    def prefix = task.ext.prefix ?: "multiBam_${metas[0].antibody}"
    def args = metas[0].single_end ? "--extendReads ${fraglen}" : ''
    if (blacklist_bed.exists()) {
      args = "${args} --blackListFileName ${blacklist_bed}"
    }
    if (task.ext.args) {
        args = "${args} ${task.ext.args}"
    }
    """
    multiBamSummary bins \\
                  --bamfiles ${bams} \\
                  --labels ${metas.collect{ it.id }.join(' ')} \\
                  --numberOfProcessors ${task.cpus} \\
                  --binSize ${params.spike_deeptools_bin_size} \\
                  --minMappingQuality ${params.spike_deeptools_min_map_quality} \\
                  --ignoreDuplicates \\
                  ${args} \\
                  -o ${prefix}_Summary.npz \\
                  --outRawCounts ${prefix}_counts.tsv \\
                  --scalingFactors ${prefix}_scalingFactors.tsv
    """
}

process BAM_COVERAGE {
    tag { meta.id }
    label 'qc'
    label 'deeptools'
    label 'process_high'

    container "${params.containers_deeptools}"

    input:
        tuple val(meta), path(bam), path(bai), val(norm_method), val(scaling_factor), val(fraglen), val(effective_genome_size)

    output:
        tuple val(meta), path("${meta.id}.bw"), emit: bigwig

    script:
    def args = meta.single_end ? "--extendReads ${fraglen}" : '--centerReads'
    """
    bamCoverage \\
      --bam ${bam} \\
      -o ${meta.id}.bw \\
      --numberOfProcessors ${task.cpus} \\
      --binSize ${params.deeptools_bin_size} \\
      --smoothLength ${params.deeptools_smooth_length} \\
      --ignoreForNormalization ${params.deeptools_excluded_chroms} \\
      --normalizeUsing ${norm_method} \\
      --effectiveGenomeSize ${effective_genome_size} \\
      --scaleFactor ${scaling_factor} \\
      ${args}
    """

    stub:
    """
    touch ${meta.id}.bw
    """

}

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

process PLOT_CORRELATION {
    label 'qc'
    label 'deeptools'
    label 'process_single'

    container "${params.containers_deeptools}"

    input:
        tuple path(array), val(plottype)

    output:
        path("*.png"), emit: png
        path("*.tab"), emit: tab

    script:
    def args = (plottype == 'heatmap')? '--plotNumbers': ''
    // TODO throw error if plottype != either'heatmap' or 'scatterplot'
    """
    plotCorrelation \\
      -in ${array} \\
      -o ${array.baseName}.${params.deeptools_corr_method}_${plottype}.png \\
      --outFileCorMatrix ${array.baseName}.${params.deeptools_corr_method}_${plottype}.tab \\
      -c '${params.deeptools_corr_method}' \\
      -p '${plottype}' \\
      --skipZeros \\
      --removeOutliers ${args}
    """

    stub:
    """
    touch ${array.baseName}.${params.deeptools_corr_method}_${plottype}.png ${array.baseName}.${params.deeptools_corr_method}_${plottype}.tab
    """
}

process PLOT_PCA {
    label 'qc'
    label 'deeptools'
    label 'process_single'

    container "${params.containers_deeptools}"

    input:
        path(array)

    output:
        path("*.pdf"), emit: pdf
        path("*.tab"), emit: tab

    script:
    """
    plotPCA \\
      -in ${array} \\
      -o ${array.baseName}.pca.pdf \\
      --outFileNameData ${array.baseName}.plotPCA.tab
    """

    stub:
    """
    touch ${array.baseName}.pca.pdf ${array.baseName}.plotPCA.tab
    """
}

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

process BED_PROTEIN_CODING {
    label 'qc'
    label 'process_single'

    container "${params.containers_base}"

    input:
      path(bed)

    output:
      path("*.protein_coding.bed"), emit: bed_prot
      path("*.all_genes.bed"),      emit: bed_all

    script:
    """
    grep --line-buffered 'protein_coding' ${bed} | awk -v OFS='\t' -F'\t' '{{print \$1, \$2, \$3, \$5, \".\", \$4}}' > ${bed.baseName}.protein_coding.bed
    cp ${bed} ${bed.baseName}.all_genes.bed
    """

    stub:
    """
    touch ${bed.baseName}.protein_coding.bed ${bed.baseName}.all_genes.bed
    """
}

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
process PLOT_HEATMAP {
  label 'qc'
  label 'deeptools'
  label 'process_high'

  container "${params.containers_deeptools}"

  input:
    path(mat)

  output:
    path("*.png"), emit: png

  script:
  // sets colorMap to "BuGn" if "metagene" in matrix filename, otherwise use "BuPu"
  def color_map = mat.baseName.contains('metagene') ? 'BuGn' : 'BuPu'
  """
  export MPLCONFIGDIR=./tmp
  plotHeatmap \\
    -m ${mat} \\
    -out ${mat.baseName}.heatmap.png \\
    --colorMap ${color_map} \\
    --yAxisLabel 'average RPGC' \\
    --regionsLabel 'genes' \\
    --legendLocation 'none'
  """

  stub:
  """
  touch ${mat.baseName}.heatmap.png
  """
}

process PLOT_PROFILE {
  label 'qc'
  label 'deeptools'
  label 'process_low'

  container "${params.containers_deeptools}"

  input:
    path(mat)

  output:
    path("*.pdf"), emit: pdf
    path("*.tab"), emit: tab

  script: // TODO set plotType for SE vs paired
  def legend_loc = mat.baseName.contains('metagene') ? 'upper-right' : 'upper-left'
  """
  plotProfile \\
    -m ${mat} \\
    --outFileName ${mat.baseName}.lineplot.pdf \\
    --outFileNameData ${mat.baseName}.plotProfile.tab \\
    --plotHeight 15 \\
    --plotWidth 15 \\
    --perGroup \\
    --yAxisLabel 'average RPGC' \\
    --plotType 'se' \\
    --legendLocation ${legend_loc}
  """

  stub:
  """
  touch ${mat.baseName}.lineplot.pdf ${mat.baseName}.plotProfile.tab
  """
}
