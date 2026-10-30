
include { CHIPSEEKER_ANNOTATE } from "../../../modules/local/chipseeker/annotate"
include { CHIPSEEKER_PLOTLIST } from "../../../modules/local/chipseeker/plotlist"
include { CHIPSEEKER_PEAKPLOT } from "../../../modules/local/chipseeker/peakplot"

workflow ANNOTATE {
    take:
        ch_peaks
        bioc_txdb
        bioc_annot
        chipseeker_enabled

    main:
        ch_plots = Channel.empty()
        if (chipseeker_enabled) {
            CHIPSEEKER_PEAKPLOT(ch_peaks, bioc_txdb, bioc_annot)
            CHIPSEEKER_ANNOTATE(ch_peaks, bioc_txdb, bioc_annot)
            ch_annot = CHIPSEEKER_ANNOTATE.out.annot
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
            ch_annot = Channel.empty()
            ch_plots = Channel.empty()
        }

    emit:
        plots = ch_plots
        annot = ch_annot
}
