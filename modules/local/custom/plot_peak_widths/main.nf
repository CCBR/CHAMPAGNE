process PLOT_PEAK_WIDTHS {
    label 'peaks'
    label 'process_single'

    container "${params.containers_r}"

    input:
        path(peak_meta)

    output:
        path("*.png")

    script:
    """
    plot_peak_widths.R ${peak_meta}
    """

    stub:
    """
    touch peak_widths.png
    """
}
