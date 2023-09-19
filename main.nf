log.info """\
         CHAMPAGNE 🍾
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
include { INPUT_CHECK } from './subworkflows/local/input_check.nf'
include { QC          } from './subworkflows/local/qc.nf'
include { CALL_PEAKS  } from './subworkflows/local/peaks.nf'

// MODULES
include { TRIM_SE                  } from "./modules/local/trim.nf"
include { ALIGN_BLACKLIST          } from "./modules/local/align.nf"
include { ALIGN_GENOME             } from "./modules/local/align.nf"
include { DEDUPLICATE              } from "./modules/local/qc.nf"
include { PHANTOM_PEAKS            } from "./modules/local/qc.nf"
include { PPQT_PROCESS             } from "./modules/local/qc.nf"
include { NORMALIZE_INPUT          } from "./modules/local/deeptools.nf"

// MAIN WORKFLOW
workflow {
    INPUT_CHECK(file(params.input), params.seq_center)
    INPUT_CHECK.out.reads.set { raw_fastqs }
    raw_fastqs | TRIM_SE
    TRIM_SE.out.set{ trimmed_fastqs }

    Channel.fromPath(params.genomes[ params.genome ].blacklist_files, checkIfExists: true)
        .collect()
        .set{ blacklist_files }
    ALIGN_BLACKLIST(trimmed_fastqs, blacklist_files)
    Channel.fromPath(params.genomes[ params.genome ].reference_files, checkIfExists: true)
        .collect()
        .set{ reference_files }
    ALIGN_GENOME(ALIGN_BLACKLIST.out.reads, reference_files)
    ALIGN_GENOME.out.bam.set{ aligned_bam }

    Channel.fromPath(params.genomes[ params.genome ].chrom_sizes, checkIfExists: true)
        .set{ chrom_sizes }
    aligned_bam.combine(chrom_sizes) | DEDUPLICATE
    DEDUPLICATE.out.bam.set{ deduped_bam }
    DEDUPLICATE.out.tag_align.set{ deduped_tagalign }

    deduped_bam | PHANTOM_PEAKS
    PHANTOM_PEAKS.out.fraglen | PPQT_PROCESS
    PPQT_PROCESS.out.fraglen.set {frag_lengths }

    if (params.run.qc) {
        QC(raw_fastqs, trimmed_fastqs,
           aligned_bam, ALIGN_GENOME.out.flagstat,
           deduped_bam, DEDUPLICATE.out.flagstat,
           PHANTOM_PEAKS.out.spp, frag_lengths
           )
        QC.out.bigwigs.set{ ch_ip_ctrl_bigwig }

        if (params.run.normalize_input) {
            ch_ip_ctrl_bigwig | NORMALIZE_INPUT
        }
    }

    if (params.run.call_peaks) {
        CALL_PEAKS(chrom_sizes, deduped_tagalign, frag_lengths)
    }
}
