include { DIFFBIND        } from "../../../subworkflows/local/diffbind/"
include { MANORM          } from "../../../subworkflows/local/manorm/"

workflow DIFF {
    take:
        bam_peaks
        tagalign_peaks
        contrasts

    main:
        bam_peaks
            .map{ meta, bam, bai, peak, ctrl_bam, ctrl_bai -> [meta.sample_basename, meta.rep] }
            .groupTuple()
            .map{ sample_basename, rep_list ->
                rep_list.unique().size()
            }
            .min() // if any sample only has one replicate, do MAnorm, otherwise do diffbind
            .set{ ch_min_reps }

        // prepare bam channel for diffbind
        bam_peaks
            .combine( contrasts )
            .map{ peak_meta, bam, bai, peak, ctrl_bam, ctrl_bai, con_meta ->
                peak_meta.sample_basename == con_meta.sample_basename ? [ peak_meta + con_meta, bam, bai, peak, ctrl_bam, ctrl_bai ] : null
            }
            .unique()
            .combine(ch_min_reps)
            .branch{ meta, bam, bai, peak, ctrl_bam, ctrl_bai, min_reps ->
                manorm: min_reps == 1
                    return (null) // tagalign files used instead of bam for manorm
                diffbind: min_reps >= 2
                    return (tuple(meta, bam, bai, peak, ctrl_bam, ctrl_bai))
            }
            .set{ bam_diff }
        // run diffbind on all samples if every sample has >= 2 replicates
        bam_diff.diffbind | DIFFBIND

        // prepare tagalign channel for manorm
        tagalign_peaks
            .combine(contrasts)
            .map{ peak_meta, tagalign, peak, con_meta ->
                peak_meta.sample_basename == con_meta.sample_basename ? [ peak_meta + con_meta, tagalign, peak ] : null
            }
            .unique()
            .combine(ch_min_reps)
            .branch{ meta, tagalign, peak, min_reps ->
                manorm: min_reps == 1
                    return (tuple(meta, tagalign, peak))
                diffbind: min_reps >= 2 // bam files used instead of tagalign for diffbind
                    return (null)
            }
            .set{ tagalign_diff }
        // run manorm on all samples if any sample has only 1 replicate
        tagalign_diff.manorm | MANORM

    emit:
        diff_peaks = bam_peaks
        // TODO

}