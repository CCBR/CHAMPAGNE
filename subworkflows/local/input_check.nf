// source: https://github.com/nf-core/chipseq/blob/51eba00b32885c4d0bec60db3cb0a45eb61e34c5/subworkflows/local/input_check.nf
//
// Check input samplesheet and get read channels
//

include { CHECK_SAMPLESHEET } from '../../modules/local/check_samplesheet.nf'
include { CHECK_CONTRASTS } from "../../modules/local/check_contrasts/"

workflow INPUT_CHECK {
    take:
        samplesheet // file: /path/to/samplesheet.csv
        seq_center  // string: sequencing center for read group
        contrastsheet // file: /path/to/contrast.tsv

    main:
        CHECK_SAMPLESHEET( samplesheet )
        samplesheet
            .splitCsv ( header:true, sep:',' )
            .map { create_fastq_channel(it, seq_center) }
            .set { reads }

        // Run check on the contrast manifest
        ch_contrasts = Channel.empty()
        
        if (contrastsheet) {
            CHECK_CONTRASTS(samplesheet, contrastsheet)
            contrastsheet
                .splitCsv( header:true, sep:'\t')
                .flatMap { row ->
                   [[[contrast: row.contrast_name, group: 'group1'],  row.group1.tokenize(',').flatten()], [[contrast: row.contrast_name, group: 'group2'], row.group2.tokenize(',').flatten()]]
                }
                .transpose() 
                .map{ meta, sample ->
                    meta.sample_basename = sample
                    [ meta ]
                }
                .set{ ch_contrasts }
        }
        

    emit:
        reads                               = reads      // channel: [ meta, [ reads ] ]
        contrasts                           = ch_contrasts // one row per sample with contrast name and group in the meta
        versions                            = CHECK_SAMPLESHEET.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channel(LinkedHashMap row, String seq_center) {
    def meta = [:]
    meta.id              = row.rep ? "${row.sample}_${row.rep}" : row.sample
    meta.sample_basename = row.sample
    meta.rep             = row.rep
    //meta.single_end      = row.single_end.toBoolean()
    meta.antibody        = row.antibody
    meta.input         = row.input
    meta.is_input        = row.input == ''

    // add path(s) of the fastq file(s) to the meta map
    def fastq_meta = []
    if (!file(row.fastq_1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
    }
    if (!row.fastq_2 && row.fastq_2.allWhitespace) { // single end
        meta.single_end = '1'.toBoolean()
        fastq_meta = [ meta, [ file(row.fastq_1) ] ]
    } else {
        if (!file(row.fastq_2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
        }
        meta.single_end = '0'.toBoolean()
        fastq_meta = [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
    }
    return fastq_meta
}

