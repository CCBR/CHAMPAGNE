
process MACS2_DEDUP {
    tag { meta.id }
    label 'dedup'
    label 'process_medium'

    container "${params.containers_macs2}"

    input:
        tuple val(meta), path(bam), path(chrom_sizes), val(effective_genome_size)

    output:
        tuple val(meta), path("${meta.id}.TagAlign.dedup.bed"), emit: bed
        tuple val(meta), path("${meta.id}.TagAlign.dedup.bam"), emit: bam

    script:
    """
    # current working directory is a tmpdir when 'scratch' is set
    TMP=tmp
    mkdir \$TMP
    trap 'rm -rf "\$TMP"' EXIT

    macs2 filterdup -i ${bam} -g ${effective_genome_size} --keep-dup="auto" -o TmpTagAlign1
    awk -F"\\t" -v OFS="\\t" '{{if (\$2>0 && \$3>0) {{print}}}}' TmpTagAlign1 > TmpTagAlign2
    awk -F"\\t" -v OFS="\\t" '{{print \$1,1,\$2}}' ${chrom_sizes} > \$TMP/GenomeFile_unsorted.bed
    sort \\
      -k1,1 -k2,2n \\
      -T \$TMP \\
      -S 2G \\
      --parallel ${task.cpus} \\
      \$TMP/GenomeFile_unsorted.bed > GenomeFile.bed
    bedtools intersect -wa -f 1.0 -a TmpTagAlign2 -b GenomeFile.bed | awk -F"\\t" -v OFS="\\t" '{\$5="0"; print}' > ${meta.id}.TagAlign.dedup.bed
    bedtools bedtobam -i ${meta.id}.TagAlign.dedup.bed -g ${chrom_sizes} > ${meta.id}.TagAlign.dedup.bam
    """

    stub:
    """
    for ext in bed bam; do
        touch ${meta.id}.TagAlign.dedup.\$ext
    done
    """
}

process PICARD_DEDUP {
    tag { meta.id }
    label 'dedup'
    label 'process_high'

    container "${params.containers_picard}"

    input:
        tuple val(meta), path(bam)

    output:
        tuple val(meta), path("${bam.baseName}.dedup.bam")                 , emit: bam
        tuple val(meta), path("${bam.baseName}.MarkDuplicates.metrics.txt"), emit: metrics
        path  "versions.yml"                                               , emit: versions

    script:
    """
    # current working directory is a tmpdir when 'scratch' is set
    TMP=tmp
    mkdir \$TMP
    trap 'rm -rf "\$TMP"' EXIT

    picard -Xmx${task.memory.toGiga()}G \\
        MarkDuplicates \\
        --INPUT ${bam} \\
        --OUTPUT ${bam.baseName}.dedup.bam \\
        --TMP_DIR \$TMP \\
        --VALIDATION_STRINGENCY SILENT \\
        --REMOVE_DUPLICATES true \\
        --METRICS_FILE ${bam.baseName}.MarkDuplicates.metrics.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard MarkDuplicates --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """

    stub:
    """
    for ext in dedup.bam MarkDuplicates.metrics.txt; do
        touch ${bam.baseName}.\$ext
    done
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard MarkDuplicates --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """
}
