include { MANORM_PAIRWISE } from "../../../modules/local/manorm/"

workflow MANORM {

    take:
        ch_tagalign_peaks
    main:
        
        ch_tagalign_peaks
            .combine(ch_tagalign_peaks)
            .map{ meta1, tag1, peak1, meta2, tag2, peak2 ->
                (meta1.tool == meta2.tool && meta1.contrast == meta2.contrast && meta1.group != meta2.group) ? [ meta1, meta2, tag1, tag2, peak1, peak2 ] : null
            }
            | MANORM_PAIRWISE

}
