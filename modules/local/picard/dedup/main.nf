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
