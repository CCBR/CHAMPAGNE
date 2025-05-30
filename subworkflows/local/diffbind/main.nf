include { PREP_DIFFBIND     } from "../../../modules/local/diffbind/prep/"
include { RMARKDOWNNOTEBOOK as DIFFBIND_RMD } from '../../../modules/nf-core/rmarkdownnotebook/'

workflow DIFFBIND {
    take:
        ch_bam_peaks_contrasts
    main:
        ch_bam_peaks_contrasts | PREP_DIFFBIND

        PREP_DIFFBIND.out.csv
            .collectFile(storeDir: "${params.outdir}/diffbind/contrasts", newLine: false, keepHeader: true, skip: 1) { meta, row ->
                [ "${meta.contrast}.${meta.tool}.csv", row ]
            }
            .map{ contrast_file ->
                params = [:]
                meta_list = contrast_file.baseName.tokenize('.')
                params.csvfile = contrast_file.getName()
                params.contrast = meta_list[0]
                params.tool = meta_list[1]

                meta = [:]
                meta.id = "${params.contrast}.${params.tool}"

                [ meta, params, contrast_file ]
            }
            .set{ contrast_files } // [ meta, params, contrast ]

        ch_bam_peaks_contrasts
            .map{ meta, bam, bai, peak, ctrl_bam, ctrl_bai ->
                [bam, bai, peak, ctrl_bam, ctrl_bai]
            }
            .mix(contrast_files.map{ meta,params,csv -> csv })
            .flatten()
            .unique()
            .collect()
            .set{ ch_data_files }

        contrast_files
            .map{ meta, params, file -> [ meta, params ] }
            .combine(Channel.fromPath(file(params.diffbind_report, checkIfExists: true)))
            .set{ ch_rmarkdown }

        DIFFBIND_RMD( ch_rmarkdown, ch_data_files )

    emit:
        report = DIFFBIND_RMD.out.report
        artifacts = DIFFBIND_RMD.out.artifacts
        versions = DIFFBIND_RMD.out.versions
}
