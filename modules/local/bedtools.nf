process BAM_TO_BED {
    tag { meta.id }

    container "${params.containers_base}"

    input:
        tuple val(meta), path(bam)

    output:
        tuple val(meta), path("${bam.baseName}.bed"), emit: bed

    script:
    """
    bedtools bamtobed -i ${bam} > ${bam.baseName}.bed
    """
    stub:
    """
    touch ${bam.baseName}.bed
    """
}
