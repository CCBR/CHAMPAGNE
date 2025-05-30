process FILTER_QUALITY {
    tag { meta.id }
    label 'align'
    label 'process_medium'

    container "${params.containers_base}"

    input:
        tuple val(meta), path(bam), path(bai)

    output:
        tuple val(meta), path("*.filtered.bam"), emit: bam

    script:
    def prefix = task.ext.prefix ?: "${bam.baseName}.filtered"
    def filter = ''
    if (meta.single_end) {
        """
        samtools view \\
            -@ ${task.cpus} \\
            -q ${params.align_min_quality} \\
            -b \\
            -o ${prefix}.bam \\
            ${bam}
        """
    } else {
        """
        bam_filter_by_mapq.py \\
            -q ${params.align_min_quality} \\
            -i ${bam} \\
            -o ${prefix}.bam
        """
    }
    stub:
    """
    touch ${bam.baseName}.filtered.bam
    """
}
