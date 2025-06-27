include { HOMER_MOTIFS        } from "../../../modules/local/homer"
include { MEME_AME            } from "../../../modules/local/meme"

workflow MOTIFS {
    take:
        ch_peaks
        genome_fasta
        meme_motifs
    main:
        ch_homer = Channel.empty()
        ch_meme = Channel.empty()
        if (params.run_homer) {
            HOMER_MOTIFS(ch_peaks.combine(genome_fasta).combine(Channel.fromPath(file(params.homer_jaspar_db, checkIfExists: true))),
                         params.homer_de_novo,
                        )
            ch_homer = HOMER_MOTIFS.out.motifs
            HOMER_MOTIFS.out.ame
                | branch{ meta, background, target ->
                    empty: background.isEmpty() | target.isEmpty()
                    fasta: true
                }
                | set{ homer_ame }
            homer_ame.empty
                | subscribe{ meta, background, target ->
                    println "Empty homer fasta for ${meta.id}"
                }
            if (params.run_meme && meme_motifs) {
                MEME_AME(homer_ame.fasta.combine(meme_motifs))
                ch_meme = MEME_AME.out.ame.mix(MEME_AME.out.seq)
            }
        }
    emit:
        homer = ch_homer
        meme = ch_meme
}
