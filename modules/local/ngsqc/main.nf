process NGSQC_GEN { // TODO segfault - https://github.com/CCBR/CHAMPAGNE/issues/13
    tag { meta.id }
    label 'qc'

    container "${params.containers_ngsqc}"

    input:
        tuple val(meta), path(bed), path(chrom_sizes)

    output:
        path("NGSQC_report.txt"), emit: report

    script:
    """
    ngsqc -v ${bed} ${chrom_sizes}
    """

    stub:
    """
    touch NGSQC_report.txt
    """
}

/*
process PLOT_NGSQC {
    // TODO refactor bin/ngsqc_plot.py for simplicity

}
*/
