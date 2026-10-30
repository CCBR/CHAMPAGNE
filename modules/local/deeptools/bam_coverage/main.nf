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
