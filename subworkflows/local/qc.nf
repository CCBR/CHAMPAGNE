
include { FASTQC as FASTQC_RAW     } from "../../modules/local/qc.nf"
include { FASTQC as FASTQC_TRIMMED } from "../../modules/local/qc.nf"
include { FASTQ_SCREEN             } from "../../modules/local/qc.nf"
include { PRESEQ                   } from "../../modules/local/qc.nf"
include { HANDLE_PRESEQ_ERROR      } from "../../modules/local/qc.nf"
include { PARSE_PRESEQ_LOG         } from "../../modules/local/qc.nf"
include { QC_STATS                 } from "../../modules/local/qc.nf"
include { QC_TABLE                 } from "../../modules/local/qc.nf"
include { MULTIQC                  } from "../../modules/local/qc.nf"

include { BAM_COVERAGE             } from "../../modules/local/deeptools.nf"
include { BIGWIG_SUM               } from "../../modules/local/deeptools.nf"
include { BED_PROTEIN_CODING       } from "../../modules/local/deeptools.nf"
include { COMPUTE_MATRIX           } from "../../modules/local/deeptools.nf"
include { PLOT_FINGERPRINT         } from "../../modules/local/deeptools.nf"
include { PLOT_CORRELATION         } from "../../modules/local/deeptools.nf"
include { PLOT_PCA                 } from "../../modules/local/deeptools.nf"
include { PLOT_HEATMAP             } from "../../modules/local/deeptools.nf"
include { PLOT_PROFILE             } from "../../modules/local/deeptools.nf"

workflow QC {
    take:
        raw_fastqs
        trimmed_fastqs
        aligned_bam
        aligned_flagstat
        deduped_bam
        deduped_flagstat
        ppqt_spp
        frag_lengths

    main:
        raw_fastqs.combine(Channel.value("raw")) | FASTQC_RAW
        trimmed_fastqs.combine(Channel.value("trimmed")) | FASTQC_TRIMMED
        trimmed_fastqs
          .combine(Channel.fromPath(params.fastq_screen.conf, checkIfExists: true))
          .combine(Channel.fromPath(params.fastq_screen.db_dir,
                                    type: 'dir', checkIfExists: true)) | FASTQ_SCREEN

        PRESEQ(aligned_bam)
        // when preseq fails, write NAs for the stats that are calculated from its log
        PRESEQ.out.log
            .join(aligned_bam, remainder: true)
            .branch { meta, preseq_log, bam_tuple ->
            failed: preseq_log == null
                return (tuple(meta, "nopresqlog"))
            succeeded: true
                return (tuple(meta, preseq_log))
            }.set{ preseq_logs }
        preseq_logs.failed | HANDLE_PRESEQ_ERROR
        preseq_logs.succeeded | PARSE_PRESEQ_LOG
        PARSE_PRESEQ_LOG.out.nrf
            .concat(HANDLE_PRESEQ_ERROR.out.nrf)
            .set{ preseq_nrf }

        QC_STATS(
            raw_fastqs,
            aligned_flagstat,
            deduped_flagstat,
            preseq_nrf,
            ppqt_spp,
            frag_lengths
        )
        QC_TABLE(QC_STATS.out.collect())

        // Deeptools

        BAM_COVERAGE(deduped_bam, frag_lengths)
        BAM_COVERAGE.out.bigwig.collect().set{ bigwig_list }
        BIGWIG_SUM(bigwig_list)
        BIGWIG_SUM.out.array.combine(Channel.from('heatmap', 'scatterplot')) | PLOT_CORRELATION
        BIGWIG_SUM.out.array | PLOT_PCA

        // Create channel: [ meta, [ ip_bam, control_bam ] [ ip_bai, control_bai ] ]
        deduped_bam
            .combine(deduped_bam)
            .map {
                meta1, bam1, bai1, meta2, bam2, bai2 ->
                    meta1.control == meta2.id ? [ meta1, [ bam1, bam2 ], [ bai1, bai2 ] ] : null
            }
            .set { ch_ip_ctrl_bam_bai }
        ch_ip_ctrl_bam_bai | PLOT_FINGERPRINT
        Channel.fromPath(params.genomes[ params.genome ].gene_info,
                         checkIfExists: true) | BED_PROTEIN_CODING
        COMPUTE_MATRIX(bigwig_list,
                       BED_PROTEIN_CODING.out.bed.combine(Channel.from('metagene','TSS'))
        )
        PLOT_HEATMAP(COMPUTE_MATRIX.out.mat)
        PLOT_PROFILE(COMPUTE_MATRIX.out.mat)

        // Create channel: [ meta, ip_bw, control_bw ]
        BAM_COVERAGE.out.meta
            .merge(BAM_COVERAGE.out.bigwig)
            .set { bigwigs }
        bigwigs
            .combine(bigwigs)
            .map {
                meta1, bw1, meta2, bw2 ->
                    meta1.control == meta2.id ? [ meta1, bw1, bw2 ] : null
            }
            .set { ch_ip_ctrl_bigwig }

        MULTIQC(
            Channel.fromPath(params.multiqc_config, checkIfExists: true),
            FASTQC_RAW.out.zip.collect(),
            FASTQC_TRIMMED.out.zip.collect(),
            FASTQ_SCREEN.out.screen.collect(),
            //NGSQC_GEN
            deduped_flagstat.collect(),
            ppqt_spp.collect(),
            QC_TABLE.out.txt,
            PLOT_FINGERPRINT.out.matrix.collect(),
            PLOT_FINGERPRINT.out.metrics.collect(),
            PLOT_CORRELATION.out.tab.collect(),
            PLOT_PCA.out.tab.collect(),
            PLOT_PROFILE.out.tab.collect()
        )

    emit:
        bigwigs = ch_ip_ctrl_bigwig
        multiqc_report = MULTIQC.out.html

}
