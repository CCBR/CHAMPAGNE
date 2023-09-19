
process ALIGN_BLACKLIST {
    tag { meta.id }
    label 'align'
    label 'process_higher'

    container = "${params.containers.base}"

    input:
        tuple val(meta), path(fastq)
        path(blacklist_files)

    output:
        tuple val(meta), path("${meta.id}.no_blacklist.fastq.gz"), emit: reads

    script: // TODO use samtools -f4 for single-end and -f12 for paired to get unmapped reads https://broadinstitute.github.io/picard/explain-flags.html
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bwa mem -t $task.cpus ${params.genomes[ params.genome ].blacklist} $fastq > ${prefix}.sam
    samtools view \\
        -@ ${task.cpus} \\
        -f4 \\
        -b \\
        ${prefix}.sam |\
    samtools bam2fq |\
    pigz -p $task.cpus > ${prefix}.no_blacklist.fastq.gz
    """

    stub:
    """
    touch ${meta.id}.no_blacklist.fastq.gz
    """
}

process ALIGN_GENOME {
    tag { meta.id }
    label 'align'
    label 'process_higher'

    container = "${params.containers.base}"

    input:
        tuple val(meta), path(fastq)
        path(reference_files)

    output:
        tuple val(meta), path("*.aligned.filtered.bam"), emit: bam
        path("*.aligned.filtered.bam.flagstat"), emit: flagstat

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # current working directory is a tmpdir when 'scratch' is set
    TMP=tmp/
    mkdir \$TMP
    trap 'rm -rf "\$TMP"' EXIT

    bwa mem -t ${task.cpus} ${params.genome} ${fastq} > ${prefix}.bam
    samtools sort \\
      -@ ${task.cpus} \\
      -m 2G \\
      -T \$TMP \\
      ${prefix}.bam > ${prefix}.sorted.bam
    samtools view \\
      -@ ${task.cpus} \\
      -q ${params.align_min_quality} \\
      -b \\
      ${prefix}.sorted.bam > ${prefix}.aligned.filtered.bam
    samtools flagstat ${prefix}.aligned.filtered.bam > ${prefix}.aligned.filtered.bam.flagstat
    """

    stub:
    """
    touch ${meta.id}.aligned.filtered.bam ${meta.id}.aligned.filtered.bam.flagstat
    """

}

process INDEX_BAM {
    tag { meta.id }
    label 'align'
    label 'process_higher'

    container = "${params.containers.base}"

    input:
        tuple val(meta), path(bam)

    output:
        tuple val(meta), path("*.bam"), path("*.bai"), emit: bam
        path("*.idxstats"), emit: idxstats

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools sort -@ ${task.cpus} -o ${prefix}.sorted.bam $bam
    samtools index ${prefix}.sorted.bam   # creates ${prefix}.sorted.bam.bai
    samtools idxstats ${prefix}.sorted.bam > ${prefix}.sorted.bam.idxstats
    """

    stub:
    """
    for ext in sorted.bam sorted.bam.bai sorted.bam.idxstats; do
        touch ${meta.id}.\$ext
    done
    """
}
