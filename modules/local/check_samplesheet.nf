// source: https://github.com/nf-core/chipseq/blob/51eba00b32885c4d0bec60db3cb0a45eb61e34c5/modules/local/CHECK_SAMPLESHEET.nf
process CHECK_SAMPLESHEET {
    tag "$samplesheet"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
        path(samplesheet)

    output:
        path('*.valid.csv') , emit: csv
        path("versions.yml"), emit: versions

    script: // This script is bundled with the pipeline, in nf-core/chipseq/bin/
    """
    check_samplesheet.py \\
        $samplesheet \\
        samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
