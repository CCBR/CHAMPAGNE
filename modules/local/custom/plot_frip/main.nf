process PLOT_FRIP {
    label 'peaks'
    label 'process_single'

    container "${params.containers_r}"

    input:
        path(frips)

    output:
        path("*.png")

    script:
    """
    plot_frip.R ${frips}
    """

    stub:
    """
    touch blank.png
    """
}
