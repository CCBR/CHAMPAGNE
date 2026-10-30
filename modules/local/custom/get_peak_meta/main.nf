process GET_PEAK_META {
    tag "${meta.id}.${peak_tool}"
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

    input:
        tuple val(meta), path(dedup_bam), path(dedup_bai), path(peaks), val(peak_tool), path(chrom_sizes)

    output:
        path("*.tsv")

    script:
    """
    awk -v id=${meta.id} -v tool=${peak_tool} 'BEGIN{FS=OFS="\\t"}{print id,tool,\$1,\$2,\$3}' ${peaks} > peak_meta_${meta.id}_${peak_tool}.tsv
    """

    stub:
    """
    touch peak_meta_${meta.id}_${peak_tool}.tsv
    """
}
