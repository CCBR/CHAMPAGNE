include { HOMER_MOTIFS        } from "../../modules/local/homer"
include { MEME_AME            } from "../../modules/local/meme"
include { CHIPSEEKER_ANNOTATE } from "../../modules/local/chipseeker/annotate"
include { CHIPSEEKER_PLOTLIST } from "../../modules/local/chipseeker/plotlist"
include { CHIPSEEKER_PEAKPLOT } from "../../modules/local/chipseeker/peakplot"

workflow ANNOTATE {
    take:
        ch_peaks
        genome_fasta
        meme_motifs
        bioc_txdb
        bioc_annot

    main:
        ch_plots = Channel.empty()
        if (params.run.chipseeker &&
         bioc_txdb && bioc_annot) {
            CHIPSEEKER_PEAKPLOT( ch_peaks, bioc_txdb, bioc_annot  )

            CHIPSEEKER_ANNOTATE( ch_peaks, bioc_txdb, bioc_annot )
            CHIPSEEKER_ANNOTATE.out.annot.collect() | CHIPSEEKER_PLOTLIST
            ch_plots = ch_plots.mix(
                CHIPSEEKER_PLOTLIST.out.plots
            )

        }
        if (params.run.homer) {
            HOMER_MOTIFS(ch_peaks.combine(genome_fasta),
                         params.homer.de_novo,
                         file(params.homer.jaspar_db, checkIfExists: true)
                        )

            if (params.run.meme && meme_motifs) {
                MEME_AME(HOMER_MOTIFS.out.ame.combine(meme_motifs))
            }
        }

    emit:
        plots = ch_plots
}
