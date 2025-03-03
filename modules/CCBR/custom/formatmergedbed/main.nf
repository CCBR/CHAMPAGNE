process CUSTOM_FORMATMERGEDBED {
    tag { meta.id }
    label 'process_medium'

    container 'nciccbr/consensus_peaks:v1.1'

    input:
    tuple val(meta), path(merged_bed)

    output:
    tuple val(meta), path("*.bed"), emit: bed
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix  = task.ext.prefix ?: "${merged_bed.baseName}.consensus_union"
    outfile = "${prefix}.bed"
    template 'format_merged_bed.R'

    stub:
    prefix  = task.ext.prefix ?: "${merged_bed.baseName}.consensus_union"
    """
    touch ${prefix}.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(R --version | grep 'R version' | sed 's/R version //; s/ (.*//'))
    END_VERSIONS
    """
}
