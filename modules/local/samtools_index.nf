process SAMTOOLS_INDEX { // TODO create/use flagstat & idxstat module in nf-modules
    tag { meta.id }
    label 'process_high'

    container = "${params.containers_base}"

    input:
        tuple val(meta), path(bam)

    output:
        tuple val(meta), path("${bam.baseName}.sort.bam"), path("${bam.baseName}.sort.bam.bai"), emit: bam
        tuple val(meta), path("${bam.baseName}.sort.bam.flagstat"), path("${bam.baseName}.sort.bam.idxstat"), emit: flagstat

    script:
    """
    # current working directory is a tmpdir when 'scratch' is set
    TMP=tmp
    mkdir \$TMP
    trap 'rm -rf "\$TMP"' EXIT

    samtools sort \\
        -@ ${task.cpus} \\
        -m 2G \\
        -T \$TMP \\
        ${bam} > ${bam.baseName}.sort.bam
    samtools index ${bam.baseName}.sort.bam
    samtools flagstat ${bam.baseName}.sort.bam > ${bam.baseName}.sort.bam.flagstat
    samtools idxstats ${bam.baseName}.sort.bam > ${bam.baseName}.sort.bam.idxstat
    """
    stub:
    """
    for ext in sort.bam sort.bam.bai sort.bam.flagstat sort.bam.idxstat; do
        touch ${bam.baseName}.\${ext}
    done
    """
}
