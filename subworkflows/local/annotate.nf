
include { CHIPSEEKER_ANNOTATE } from "../../modules/local/chipseeker/annotate"
include { CHIPSEEKER_PLOTLIST } from "../../modules/local/chipseeker/plotlist"
include { CHIPSEEKER_PEAKPLOT } from "../../modules/local/chipseeker/peakplot"

workflow ANNOTATE {
    take:
        ch_peaks
        bioc_txdb
        bioc_annot

    main:
        ch_plots = Channel.empty()
        if (params.run_chipseeker &&
         bioc_txdb && bioc_annot) {
            CHIPSEEKER_PEAKPLOT( ch_peaks, bioc_txdb, bioc_annot  )

            CHIPSEEKER_ANNOTATE( ch_peaks, bioc_txdb, bioc_annot )
            CHIPSEEKER_ANNOTATE.out.annot
                | map{ meta, annot -> [meta.consensus, meta, annot] }
                | groupTuple()
                | map{ consensus, metas, annots ->
                    def meta2 = [:]
                    meta2.consensus = consensus
                    [ meta2, annots ]
                }
                | CHIPSEEKER_PLOTLIST
            CHIPSEEKER_PLOTLIST.out.plots
                | set{ ch_plots }

        }

    emit:
        plots = ch_plots
        annotations = CHIPSEEKER_ANNOTATE.out.annot
}
