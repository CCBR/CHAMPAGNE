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
