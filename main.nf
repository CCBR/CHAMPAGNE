nextflow.enable.dsl = 2
nextflow.preview.output = true

// SUBWORKFLOWS
include { FASTQ_DOWNLOAD_PREFETCH_FASTERQDUMP_SRATOOLS as DOWNLOAD_FASTQ } from './subworkflows/nf-core/fastq_download_prefetch_fasterqdump_sratools/'
include { INPUT_CHECK              } from './subworkflows/local/input_check.nf'
include { PREPARE_GENOME           } from './subworkflows/local/prepare_genome.nf'
include { ALIGN_SPIKEIN            } from './subworkflows/local/spikein/'
include { POOL_INPUTS              } from './subworkflows/local/pool_inputs/'
include { FILTER_BLACKLIST         } from './subworkflows/CCBR/filter_blacklist/'
include { ALIGN_GENOME             } from "./subworkflows/local/align.nf"
include { DEDUPLICATE              } from "./subworkflows/local/deduplicate.nf"
include { DEEPTOOLS                } from "./subworkflows/local/deeptools"
include { QC                       } from './subworkflows/local/qc.nf'
include { CALL_PEAKS               } from './subworkflows/local/peaks.nf'
include { CONSENSUS_PEAKS as CONSENSUS_UNION } from './subworkflows/CCBR/consensus_peaks/'
include { MOTIFS as MOTIFS_PEAKS;
          MOTIFS as MOTIFS_CONS_UNION;
          MOTIFS as MOTIFS_CONS_CORCES       } from './subworkflows/local/motifs/'
include { ANNOTATE as ANNOTATE_CONS_UNION;
          ANNOTATE as ANNOTATE_CONS_CORCES   } from './subworkflows/local/annotate.nf'
include { DIFF                     } from './subworkflows/local/differential/'

// MODULES
include { CUTADAPT                 } from "./modules/CCBR/cutadapt/"
include { PHANTOM_PEAKS
          PPQT_PROCESS
          MULTIQC                  } from "./modules/local/qc.nf"
include { CONSENSUS_CORCES         } from "./modules/local/consensus/corces/main.nf"
// Plugins
include { validateParameters; paramsSummaryLog } from 'plugin/nf-schema'

workflow.onComplete {
    if (!workflow.stubRun && !workflow.commandLine.contains('-preview')) {
        def message = Utils.spooker(workflow)
        if (message) {
            println message
        }
    }
}

workflow version {
    println "CHAMPAGNE ${workflow.manifest.version}"
}

workflow debug {

    sample_sheet = Channel.fromPath(file(params.input, checkIfExists: true))
    contrast_sheet = params.contrasts ? Channel.fromPath(file(params.contrasts, checkIfExists: true)) : params.contrasts
    raw_fastqs = INPUT_CHECK(sample_sheet, contrast_sheet).reads

}

workflow DOWNLOAD_SRA {
    ch_sra = Channel.from(file(params.sra_csv)) // assets/test_human_metadata.csv
        .splitCsv ( header:true, sep:',' )
        .map{ it -> [ it + [id: it.sra], it.sra ]}
        .view()
    DOWNLOAD_FASTQ(ch_sra, file('BLANK'))

}

workflow MAKE_REFERENCE {
    PREPARE_GENOME()
}


workflow LOG {
    log.info """\
            CHAMPAGNE $workflow.manifest.version
            ===================================
            cmd line     : $workflow.commandLine
            start time   : $workflow.start
            launchDir    : $workflow.launchDir
            input        : ${params.input}
            genome       : ${params.genome}
            """
            .stripIndent()

    log.info paramsSummaryLog(workflow)
}


// MAIN WORKFLOW
workflow {
    main:
    LOG()
    validateParameters()

    // initialize output channels
    ch_multiqc = Channel.empty()
    multiqc_report = channel.empty()
    fastqc_raw = Channel.empty()
    fastqc_trimmed = Channel.empty()
    ch_peaks = Channel.empty()
    ch_peaks_consensus = Channel.empty()
    ch_annot = Channel.empty()
    ch_motifs_homer = Channel.empty()
    ch_motifs_meme = Channel.empty()
    ch_diffbind = Channel.empty()
    ch_manorm = Channel.empty()

    sample_sheet = Channel.fromPath(file(params.input, checkIfExists: true))
    contrast_sheet = params.contrasts ? Channel.fromPath(file(params.contrasts, checkIfExists: true)) : params.contrasts
    raw_fastqs = INPUT_CHECK(sample_sheet, contrast_sheet).reads

    CUTADAPT(raw_fastqs).reads | POOL_INPUTS
    trimmed_fastqs = POOL_INPUTS.out.reads

    PREPARE_GENOME()
    chrom_sizes = PREPARE_GENOME.out.chrom_sizes
    effective_genome_size = PREPARE_GENOME.out.effective_genome_size

    FILTER_BLACKLIST(trimmed_fastqs, PREPARE_GENOME.out.blacklist_index)
    ALIGN_GENOME(FILTER_BLACKLIST.out.reads, PREPARE_GENOME.out.reference_index)
    aligned_bam = ALIGN_GENOME.out.bam

    DEDUPLICATE(aligned_bam, chrom_sizes, effective_genome_size)
    deduped_bam = DEDUPLICATE.out.bam
    deduped_tagalign = DEDUPLICATE.out.tag_align

    PHANTOM_PEAKS(deduped_bam).fraglen | PPQT_PROCESS
    frag_lengths = PPQT_PROCESS.out.fraglen
    ch_ppqt = PHANTOM_PEAKS.out.pdf.mix(
        PHANTOM_PEAKS.out.spp,
        PHANTOM_PEAKS.out.fraglen
    )

    // optional spike-in normalization
    if (params.spike_genome) {
        ALIGN_SPIKEIN(trimmed_fastqs, params.spike_genome, frag_lengths)
        ch_scaling_factors = ALIGN_SPIKEIN.out.scaling_factors
        ch_multiqc = ch_multiqc.mix(ALIGN_SPIKEIN.out.sf_tsv)
    } else {
        ch_scaling_factors = trimmed_fastqs
            | map{ meta, fq -> meta.id }
            | combine(Channel.of(1))
    }

    if (params.run_deeptools) {
        DEEPTOOLS( deduped_bam,
                    frag_lengths,
                    effective_genome_size,
                    PREPARE_GENOME.out.gene_info,
                    ch_scaling_factors
                    )
        ch_deeptools_bw = DEEPTOOLS.out.bigwigs
        ch_deeptools_bw_input_norm = DEEPTOOLS.out.bigwigs_input_norm
        ch_deeptools_stats = DEEPTOOLS.out.fingerprint_matrix
            .mix(
                DEEPTOOLS.out.fingerprint_metrics,
                DEEPTOOLS.out.corr,
                DEEPTOOLS.out.pca,
                DEEPTOOLS.out.profile,
                DEEPTOOLS.out.heatmap
            )
        ch_multiqc = ch_multiqc.mix(ch_deeptools_stats)
    } else {
        ch_deeptools_bw = Channel.empty()
        ch_deeptools_bw_input_norm = Channel.empty()
        ch_deeptools_stats = Channel.empty()
    }

    if (params.run_qc) {
        QC(raw_fastqs, CUTADAPT.out.reads, FILTER_BLACKLIST.out.n_surviving_reads,
           aligned_bam, ALIGN_GENOME.out.aligned_flagstat, ALIGN_GENOME.out.filtered_flagstat,
           DEDUPLICATE.out.flagstat,
           PHANTOM_PEAKS.out.spp, frag_lengths,
           )
        ch_multiqc = ch_multiqc.mix(QC.out.multiqc_input)
        fastqc_raw = QC.out.fastqc_raw
        fastqc_trimmed = QC.out.fastqc_trimmed
    }

    if ([params.run_macs_broad, params.run_macs_narrow, params.run_gem, params.run_sicer].any()) {

        CALL_PEAKS(chrom_sizes,
                   PREPARE_GENOME.out.chrom_dir,
                   deduped_tagalign,
                   deduped_bam,
                   frag_lengths,
                   effective_genome_size
                   )
        ch_multiqc = ch_multiqc.mix(CALL_PEAKS.out.plots)
        ch_peaks = CALL_PEAKS.out.peaks

        // consensus peak calling with union method
        if (params.run_consensus_union) {
            ch_peaks_grouped = CALL_PEAKS.out.peaks
                .map{ meta, bed, tool ->
                    [ [ group: "${meta.sample_basename}.${tool}" ], bed ]
                }
            CONSENSUS_UNION( ch_peaks_grouped, params.run_normalize_peaks )
            // retrieve sample basename and peak-calling tool from metadata
            CONSENSUS_UNION.out.peaks
                .map{ meta, bed ->
                    def meta_split = meta.id.tokenize('.')
                    assert meta_split.size() == 2
                    [ [ id: meta_split[0], tool: meta_split[1], consensus: 'union' ], bed ]
                }
                .set{ ch_consensus_union }
            ANNOTATE_CONS_UNION(ch_consensus_union,
                    PREPARE_GENOME.out.bioc_txdb,
                    PREPARE_GENOME.out.bioc_annot)
            MOTIFS_CONS_UNION(ch_consensus_union,
                    PREPARE_GENOME.out.fasta,
                    PREPARE_GENOME.out.meme_motifs)
            ch_peaks_consensus = ch_peaks_consensus.mix(ch_consensus_union)

            ch_multiqc = ch_multiqc.mix(ANNOTATE_CONS_UNION.out.plots)
            ch_annot = ch_annot.mix(ANNOTATE_CONS_UNION.out.annot)
            ch_motifs_homer = ch_motifs_homer.mix(MOTIFS_CONS_UNION.out.homer)
            ch_motifs_meme = ch_motifs_meme.mix(MOTIFS_CONS_UNION.out.meme)
        }
        if (params.run_consensus_corces) {
            // consensus peak calling with corces method
            // only works on narrowPeak files, as the 10th column is the summit coordinate
            ch_narrow_peaks = CALL_PEAKS.out.narrow_peaks
                .map{ meta, bed, tool ->
                    def meta2 = [tool: tool, id: meta.sample_basename]
                    [ meta2, bed ]
                }
                .groupTuple()
            ch_narrow_peaks.combine(chrom_sizes)
                | CONSENSUS_CORCES
                | map{ meta, peak ->
                    def meta2 = meta
                    meta2.consensus = 'corces'
                    [ meta2, peak ]
                }

            ANNOTATE_CONS_CORCES(CONSENSUS_CORCES.out.peaks,
                    PREPARE_GENOME.out.bioc_txdb,
                    PREPARE_GENOME.out.bioc_annot)
            MOTIFS_CONS_CORCES(CONSENSUS_CORCES.out.peaks,
                    PREPARE_GENOME.out.fasta,
                    PREPARE_GENOME.out.meme_motifs)
            ch_peaks_consensus.mix(CONSENSUS_CORCES.out.peaks)

            ch_multiqc = ch_multiqc.mix(ANNOTATE_CONS_CORCES.out.plots)
            ch_annot = ch_annot.mix(ANNOTATE_CONS_CORCES.out.annot)
            ch_motifs_homer = ch_motifs_homer.mix(MOTIFS_CONS_CORCES.out.homer)
            ch_motifs_meme = ch_motifs_meme.mix(MOTIFS_CONS_CORCES.out.meme)
        }

        // run differential analysis
        ch_contrasts = INPUT_CHECK.out.contrasts
        if (params.contrasts) {
            // TODO use consensus peaks for regions of interest in diffbind (merge peaks within contrast to create ROI)
            CALL_PEAKS.out.bam_peaks
                .combine(deduped_bam)
                .map{meta1, bam1, bai1, peak, tool, meta2, bam2, bai2 ->
                    meta1.input == meta2.id ? [ meta1 + [tool: tool], bam1, bai1, peak, bam2, bai2 ] : null
                }
                .set{bam_peaks}
            CALL_PEAKS.out.tagalign_peaks
                .join(frag_lengths)
                .map{ meta, tagalign, peak, tool, frag_len ->
                    [ meta + [tool: tool, fraglen: frag_len], tagalign, peak ]
                }
                .set{ tagalign_peaks }
            DIFF( bam_peaks,
                  tagalign_peaks,
                  ch_contrasts
                )
            ch_diffbind = DIFF.out.diffbind
            ch_manorm = DIFF.out.manorm
        }

    }

    ch_multiqc = ch_multiqc.collect()
    if (!workflow.stubRun) {
        MULTIQC(
            file(params.multiqc_config, checkIfExists: true),
            file(params.multiqc_logo, checkIfExists: true),
            ch_multiqc
        )
        multiqc_report = MULTIQC.out
    }


    publish:
        genome = PREPARE_GENOME.out.conf
        fastqc_raw = fastqc_raw
        fastqc_trimmed = fastqc_trimmed
        ppqt = ch_ppqt
        deeptools_bw = ch_deeptools_bw
        deeptools_bw_input_norm = ch_deeptools_bw_input_norm
        deeptools_stats = ch_deeptools_stats
        multiqc_report = multiqc_report
        multiqc_inputs = ch_multiqc
        align_bam = DEDUPLICATE.out.bam
        peaks = ch_peaks
        peaks_consensus = ch_peaks_consensus
        annot = ch_annot
        homer = ch_motifs_homer
        meme = ch_motifs_meme
        diffbind = ch_diffbind
        manorm = ch_manorm

}


output {

    genome { path { conf -> "genome/" } }
    fastqc_raw {
        path { raw -> "qc/fastqc/raw/" }
    }
    fastqc_trimmed {
        path { trimmed -> "qc/fastqc/trimmed/" }
    }
    ppqt {
        path { file -> "qc/phantompeakqualtools/" }
    }
    deeptools_bw {
        path { bigwig -> "bigwigs/" }
    }
    deeptools_bw_input_norm {
        path { bigwig -> "bigwigs/" }
    }
    deeptools_stats {
        path { deeptools -> "qc/deeptools/" }
    }
    multiqc_report {
        path { report -> "qc/multiqc/"}
    }
    multiqc_inputs {
        path { inputs -> "qc/multiqc/inputs/" }
    }
    align_bam {
        path { bam -> "align/bam/" }
    }
    peaks {
        path { meta, peak, tool -> "peaks/${meta.tool}/replicates/"}
    }
    peaks_consensus {
        path { meta, peak -> "peaks/${meta.tool}/consensus/${meta.consensus}/" }
    }
    annot {
        path { meta, file -> "peaks/${meta.tool}/consensus/${meta.consensus}/annotations/" }
    }
    homer {
        path { meta, file -> "peaks/${meta.tool}/consensus/${meta.consensus}/motifs/homer/" }
    }
    meme {
        path { meta, file -> "peaks/${meta.tool}/consensus/${meta.consensus}/motifs/meme/" }
    }
    diffbind {
        path { meta, report -> "peaks/${meta.tool}/diff/diffbind/${meta.contrast}/" }
    }
    manorm {
        path { meta, files -> "peaks/${meta.tool}/diff/manorm/${meta.contrast}/" }
    }

}
