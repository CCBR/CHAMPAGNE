process PLOT_JACCARD {
    label 'peaks'
    label 'process_single'

    container "${params.containers_r}"

    input:
        path(jaccard)

    output:
        path("*.png")

    script:
    """
    plot_jaccard.R ${jaccard}
    """

    stub:
    """
    touch plot.png
    """

}
