// source: https://github.com/nf-core/chipseq/blob/51eba00b32885c4d0bec60db3cb0a45eb61e34c5/subworkflows/local/input_check.nf
//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check.nf'
include { CHECK_CONTRASTS } from "../../modules/local/check_contrasts/"

workflow INPUT_CHECK {
    take:
        samplesheet // file: /path/to/samplesheet.csv
        seq_center  // string: sequencing center for read group
        contrastsheet // file: /path/to/contrast.yaml

    main:
        valid_csv = SAMPLESHEET_CHECK( samplesheet ).csv
        valid_csv
            .splitCsv ( header:true, sep:',' )
            .map { create_fastq_channel(it, seq_center) }
            .set { reads }

        // Run check on the contrast manifest
        ch_contrasts = Channel.empty()
        if (contrastsheet) {
            CHECK_CONTRASTS(valid_csv, contrastsheet)
                .csv
                .flatten()
                .splitCsv( header: true, sep: ',' )
                .map{ it ->
                    meta = get_contrast_meta(it)
                    [ sample_basename: meta.sample_basename, group: meta.group, contrast: meta.contrast ]
                }
                .unique()
                .set{ ch_contrasts }
        }

    emit:
        reads                               = reads      // channel: [ val(meta), [ reads ] ]
        csv                                 = valid_csv
        contrasts                           = ch_contrasts
        versions                            = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_fastq_channel(LinkedHashMap row, String seq_center) {
    def meta = [:]
    meta.id              = row.sample
    meta.sample_basename = row.sample_basename
    meta.rep             = row.rep
    meta.single_end      = row.single_end.toBoolean()
    meta.antibody        = row.antibody
    meta.control         = row.control
    meta.is_input        = row.control == ''

    // add path(s) of the fastq file(s) to the meta map
    def fastq_meta = []
    if (!file(row.fastq_1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
    }
    if (meta.single_end) {
        fastq_meta = [ meta, [ file(row.fastq_1) ] ]
    } else {
        if (!file(row.fastq_2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
        }
        fastq_meta = [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
    }
    return fastq_meta
}

// Function to get contrast list of [meta, [id, sample_basename, rep, single_end, antibody, control, group, contrast]]
def get_contrast_meta(LinkedHashMap row) {
    def meta = [:]
    meta.id              = row.sample
    meta.sample_basename = row.sample_basename
    meta.rep             = row.rep
    meta.single_end      = row.single_end.toBoolean()
    meta.antibody        = row.antibody
    meta.control         = row.control
    meta.group           = row.group
    meta.contrast        = row.contrast

    return meta
}
