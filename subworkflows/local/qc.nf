// modules
include { FASTQC as FASTQC_RAW     } from "../../modules/local/qc.nf"
include { FASTQC as FASTQC_TRIMMED } from "../../modules/local/qc.nf"
include { FASTQ_SCREEN             } from "../../modules/local/qc.nf"
include { PRESEQ                   } from "../../modules/local/qc.nf"
include { HANDLE_PRESEQ_ERROR      } from "../../modules/local/qc.nf"
include { PARSE_PRESEQ_LOG         } from "../../modules/local/qc.nf"
include { QC_STATS                 } from "../../modules/local/qc.nf"
include { QC_TABLE                 } from "../../modules/local/qc.nf"
include { MULTIQC                  } from "../../modules/local/qc.nf"

// subworkflows
include { DEEPTOOLS                } from "../../subworkflows/local/deeptools"

workflow QC {
    take:
        raw_fastqs
        trimmed_fastqs
        n_reads_surviving_blacklist
        aligned_filtered_bam
        aligned_flagstat
        filtered_flagstat
        deduped_bam
        deduped_flagstat
        ppqt_spp
        frag_lengths
        gene_info
        effective_genome_size

    main:
        raw_fastqs.combine(Channel.value("raw")) | FASTQC_RAW
        trimmed_fastqs.combine(Channel.value("trimmed")) | FASTQC_TRIMMED
        ch_multiqc = Channel.empty()
        trimmed_fastqs
            .combine(Channel.fromPath(params.fastq_screen_conf, checkIfExists: true))
            .combine(Channel.fromPath(params.fastq_screen_db_dir,
                                        type: 'dir', checkIfExists: true)) | FASTQ_SCREEN
        ch_multiqc = ch_multiqc.mix(FASTQ_SCREEN.out.screen)

        PRESEQ(aligned_filtered_bam)
        // when preseq fails, write NAs for the stats that are calculated from its log
        PRESEQ.out.log
            .join(aligned_filtered_bam, remainder: true)
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

        qc_stats_input = raw_fastqs
            .join(n_reads_surviving_blacklist)
            .join(aligned_flagstat)
            .join(filtered_flagstat)
            .join(deduped_flagstat)
            .join(preseq_nrf)
            .join(ppqt_spp)
            .join(frag_lengths)
        QC_STATS( qc_stats_input )
        QC_TABLE( QC_STATS.out.collect() )

        deduped_flagstat
            .map { meta, flagstat, idxstat ->
                [ flagstat, idxstat ]
            }
            .set{ dedup_flagstat_files }
        ppqt_spp
            .map { meta, spp ->
                [ spp ]
            }
            .set{ ppqt_spp_files }
        ch_multiqc = ch_multiqc.mix(
            FASTQC_RAW.out.zip,
            FASTQC_TRIMMED.out.zip,
            dedup_flagstat_files,
            ppqt_spp_files,
            QC_TABLE.out.txt,
            PRESEQ.out.c_curve
        )

        if (params.run_deeptools) {
            DEEPTOOLS( deduped_bam,
                       frag_lengths,
                       effective_genome_size,
                       gene_info
                     )
            ch_multiqc = ch_multiqc.mix(
                DEEPTOOLS.out.fingerprint_matrix,
                DEEPTOOLS.out.fingerprint_metrics,
                DEEPTOOLS.out.corr,
                DEEPTOOLS.out.pca,
                DEEPTOOLS.out.profile,
                DEEPTOOLS.out.heatmap
            )
        }

    emit:
        multiqc_input = ch_multiqc

}
