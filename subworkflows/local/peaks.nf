
include { CALC_GENOME_FRAC } from "../../modules/local/peaks.nf"
include { SICER            } from "../../modules/local/peaks.nf"
include { MACS_BROAD       } from "../../modules/local/peaks.nf"
include { MACS_NARROW      } from "../../modules/local/peaks.nf"
include { GEM              } from "../../modules/local/peaks.nf"


workflow CALL_PEAKS {
    take:
        chrom_sizes
        deduped_tagalign
        frag_lengths

    main:
        // peak calling
        genome_frac = CALC_GENOME_FRAC(chrom_sizes)
        // create channel with [ meta, chip_tag, input_tag, fraglen, genome_frac]
        deduped_tagalign
            .combine(deduped_tagalign)
            .map {
                meta1, tag1, meta2, tag2 ->
                    meta1.control == meta2.id ? [ meta1, tag1, tag2 ]: null
            }
            .join(frag_lengths)
            .combine(genome_frac)
            .set { ch_tagalign }

        deduped_tagalign
            .combine(deduped_tagalign)
            .map {
                meta1, tag1, meta2, tag2 ->
                    meta1.control == meta2.id ? [ meta1, tag1, tag2 ]: null
            }
            .combine(Channel.fromPath(params.gem_read_dists, checkIfExists: true))
            .combine(chrom_sizes)
            .set { ch_gem }
        Channel.fromPath("${params.genomes[ params.genome ].chromosomes_dir}", type: 'dir', checkIfExists: true)
            .set{ chrom_files }

        ch_tagalign | MACS_BROAD
        ch_tagalign | MACS_NARROW
        ch_tagalign | SICER
        GEM(ch_gem, chrom_files)

    emit:
        macs_broad_peaks = MACS_BROAD.out.broad_peak
        macs_narrow_peaks = MACS_NARROW.out.narrow_peak
        sicer_peaks = SICER.out
        gem_peaks = GEM.out.events
}
