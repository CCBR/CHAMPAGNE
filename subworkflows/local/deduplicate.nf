include { MACS2_DEDUP; PICARD_DEDUP      } from "../../modules/local/deduplicate.nf"
include { SAMTOOLS_INDEX as INDEX_SINGLE
          SAMTOOLS_INDEX as INDEX_PAIRED } from "../../modules/local/samtools_index.nf"
workflow DEDUPLICATE {
    take:
        aligned_bam
        chrom_sizes
        effective_genome_size

    main:
        // branch reads: single end to macs2 filterdup, paired end to picard markduplicates
        aligned_bam.branch { meta, bam ->
            single: meta.single_end
            paired: !meta.single_end

        }.set{ bam }
        bam.single.combine(chrom_sizes).combine(effective_genome_size) | MACS2_DEDUP
        MACS2_DEDUP.out.bam | INDEX_SINGLE
        bam.paired | PICARD_DEDUP
        PICARD_DEDUP.out.bam | INDEX_PAIRED
        INDEX_PAIRED.out.bam
            .mix(INDEX_SINGLE.out.bam)
            .set{ ch_bam_bai }
        INDEX_PAIRED.out.flagstat
            .mix(INDEX_SINGLE.out.flagstat)
            .set{ ch_flagstat }
        // mix single bed and paired bam channel for peak callers, with variable to designate format
        INDEX_PAIRED.out.bam
            .map{ meta, bam, bai ->
                [ meta, bam ]
            }
            .combine(Channel.value("BAMPE"))
            .mix(MACS2_DEDUP.out.bed.combine(Channel.value("BED")))
            .set{ mixed_tagAlign } // [meta, bed/bam, bampe/bed]

    emit:
        bam = ch_bam_bai
        tag_align = mixed_tagAlign
        flagstat = ch_flagstat
}
