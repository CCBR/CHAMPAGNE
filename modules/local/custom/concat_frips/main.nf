process CONCAT_FRIPS {
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

    input:
        path(frips)

    output:
        path("FRiP.txt")

    script:
    """
    head -n 1 ${frips.get(1)} > FRiP.txt
    for f in ${frips}; do
        tail -n 1 \$f >> FRiP.txt
    done
    """
    stub:
    """
    touch FRiP.txt
    """

}
