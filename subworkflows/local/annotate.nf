
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
        if (params.run_chipseeker && bioc_txdb && bioc_annot) {
            CHIPSEEKER_PEAKPLOT( ch_peaks, bioc_txdb, bioc_annot  )
            // CHIPSEEKER_PEAKPLOT.out.plots
            //     | map{ meta, plot -> [ plot ]}
            //     | set{ ch_plots }

            CHIPSEEKER_ANNOTATE( ch_peaks, bioc_txdb, bioc_annot )
            CHIPSEEKER_ANNOTATE.out.annot
                | set{ ch_annot }
            ch_annot
                | map{ meta, annot -> [meta.consensus, meta, annot] }
                | groupTuple()
                | map{ consensus, metas, annots ->
                    def meta2 = [:]
                    meta2.consensus = consensus
                    [ meta2, annots ]
                }
                | CHIPSEEKER_PLOTLIST

            ch_plots = ch_plots.mix(CHIPSEEKER_PLOTLIST.out)
                .collect()
                .flatten()
        } else {
            ch_plots = Channel.empty()
            ch_annot = Channel.empty()
        }

    emit:
        plots = ch_plots
        annot = ch_annot
}
