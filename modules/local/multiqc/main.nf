process MULTIQC {
    container "${params.containers_multiqc}"

    input:
        path(multiqc_conf)
        path(custom_logo)
        path(input_files)

    output:
        path('multiqc_report.html'), emit: html

    script:
    """
    multiqc \\
        -c ${multiqc_conf} \\
        .
    """

    stub:
    """
    touch multiqc_report.html
    """
}
