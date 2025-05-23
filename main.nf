log.info """\
         CHAMPAGNE $workflow.manifest.version 🍾
         =============
         NF version   : $nextflow.version
         runName      : $workflow.runName
         username     : $workflow.userName
         configs      : $workflow.configFiles
         profile      : $workflow.profile
         cmd line     : $workflow.commandLine
         start time   : $workflow.start
         projectDir   : $workflow.projectDir
         launchDir    : $workflow.launchDir
         workDir      : $workflow.workDir
         homeDir      : $workflow.homeDir
         input        : ${params.input}
         genome       : ${params.genome}
         """
         .stripIndent()

// SUBWORKFLOWS
include { FASTQ_DOWNLOAD_PREFETCH_FASTERQDUMP_SRATOOLS as DOWNLOAD_FASTQ } from './subworkflows/nf-core/fastq_download_prefetch_fasterqdump_sratools/'
include { INPUT_CHECK              } from './subworkflows/local/input_check.nf'
include { PREPARE_GENOME           } from './subworkflows/local/prepare_genome.nf'
include { POOL_INPUTS              } from './subworkflows/local/pool_inputs/'
include { FILTER_BLACKLIST         } from './subworkflows/CCBR/filter_blacklist/'
include { ALIGN_GENOME             } from "./subworkflows/local/align.nf"
include { DEDUPLICATE              } from "./subworkflows/local/deduplicate.nf"
include { QC                       } from './subworkflows/local/qc.nf'
include { CALL_PEAKS               } from './subworkflows/local/peaks.nf'
include { CONSENSUS_PEAKS as CONSENSUS_UNION } from './subworkflows/CCBR/consensus_peaks/'
include { ANNOTATE as ANNOTATE_CONS_UNION;
          ANNOTATE as ANNOTATE_CONS_CORCES   } from './subworkflows/local/annotate.nf'
include { DIFF                     } from './subworkflows/local/differential/'

// MODULES
include { CUTADAPT                 } from "./modules/CCBR/cutadapt/"
include { PHANTOM_PEAKS
          PPQT_PROCESS
          MULTIQC                  } from "./modules/local/qc.nf"
include { CONSENSUS_CORCES         } from "./modules/local/consensus/corces/main.nf"


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
    raw_fastqs = INPUT_CHECK(sample_sheet, params.seq_center, contrast_sheet).reads

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

// MAIN WORKFLOW
workflow {
    CHIPSEQ()
}

workflow CHIPSEQ {
    sample_sheet = Channel.fromPath(file(params.input, checkIfExists: true))
    contrast_sheet = params.contrasts ? Channel.fromPath(file(params.contrasts, checkIfExists: true)) : params.contrasts
    raw_fastqs = INPUT_CHECK(sample_sheet, params.seq_center, contrast_sheet).reads

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

    ch_multiqc = Channel.of()
    if (params.run.qc) {
        QC(raw_fastqs, CUTADAPT.out.reads, FILTER_BLACKLIST.out.n_surviving_reads,
           aligned_bam, ALIGN_GENOME.out.aligned_flagstat, ALIGN_GENOME.out.filtered_flagstat,
           deduped_bam, DEDUPLICATE.out.flagstat,
           PHANTOM_PEAKS.out.spp, frag_lengths,
           PREPARE_GENOME.out.gene_info,
           effective_genome_size
           )
        ch_multiqc = ch_multiqc.mix(QC.out.multiqc_input)
    }
    if (params.run.call_peaks && [params.run.macs_broad, params.run.macs_narrow, params.run.gem, params.run.sicer].any()) {
        CALL_PEAKS(chrom_sizes,
                   PREPARE_GENOME.out.chrom_dir,
                   deduped_tagalign,
                   deduped_bam,
                   frag_lengths,
                   effective_genome_size
                   )
        ch_multiqc = ch_multiqc.mix(CALL_PEAKS.out.plots)
        // consensus peak calling with union method
        if (params.run.consensus_union) {
            ch_peaks_grouped = CALL_PEAKS.out.peaks
                .map{ meta, bed, tool ->
                    [ [ group: "${meta.sample_basename}.${tool}" ], bed ]
                }
            CONSENSUS_UNION( ch_peaks_grouped, params.run.normalize_peaks )
            // retrieve sample basename and peak-calling tool from metadata
            CONSENSUS_UNION.out.peaks
                .map{ meta, bed ->
                    def meta_split = meta.id.tokenize('.')
                    assert meta_split.size() == 2
                    [ [ sample_basename: meta_split[0], tool: meta_split[1] ], bed ]
                }
                .set{ ch_consensus_union }
            ANNOTATE_CONS_UNION(CONSENSUS_UNION.out.peaks,
                    PREPARE_GENOME.out.fasta,
                    PREPARE_GENOME.out.meme_motifs,
                    PREPARE_GENOME.out.bioc_txdb,
                    PREPARE_GENOME.out.bioc_annot)
            ch_multiqc = ch_multiqc.mix(ANNOTATE_CONS_UNION.out.plots)
        }
        if (params.run.consensus_corces) {
            // consensus peak calling with corces method
            // only works on narrowPeak files, as the 10th column is the summit coordinate
            ch_narrow_peaks = CALL_PEAKS.out.narrow_peaks
                .map{ meta, bed, tool ->
                    def meta2 = [tool: tool, id: meta.sample_basename]
                    [ meta2, bed ]
                }
                .groupTuple()
            CONSENSUS_CORCES(ch_narrow_peaks.combine(chrom_sizes))
            ANNOTATE_CONS_CORCES(CONSENSUS_CORCES.out.peaks,
                    PREPARE_GENOME.out.fasta,
                    PREPARE_GENOME.out.meme_motifs,
                    PREPARE_GENOME.out.bioc_txdb,
                    PREPARE_GENOME.out.bioc_annot)
            ch_multiqc = ch_multiqc.mix(ANNOTATE_CONS_CORCES.out.plots)
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

        }

    }

    if (!workflow.stubRun) {
        MULTIQC(
            file(params.multiqc.config, checkIfExists: true),
            file(params.multiqc.logo, checkIfExists: true),
            ch_multiqc.collect()
        )
    }
}
