
process SAMTOOLS_COUNT {
    // Given a bam file, count the number of reads that aligned.

    tag { meta.id }
    label 'process_high'

    container 'nciccbr/ccbr_ubuntu_base_20.04:v6'

    input:
        tuple val(meta), path(bam), path(bai)

    output:
        tuple val(meta), env('COUNT'),          emit: count
        path("versions.yml"),                   emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def filter_flag = meta.single_end ? '-F 4' : '-f 2'
    def samtools_args = task.ext.args ?: "${filter_flag} -q 30"
    def printf_args = meta.single_end ? '\\$1' : '\\$1/2'
    """
    COUNT=\$( samtools view \\
            -@ ${task.cpus} \\
            ${samtools_args} \\
            ${bam} |\\
        wc -l |\\
        awk "{{printf ${printf_args}}}"
    )
    echo -e "count: \${COUNT}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch versions.yml
    COUNT=0
    """
}
