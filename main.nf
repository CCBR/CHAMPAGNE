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
         reads        : ${params.reads}
         """
         .stripIndent()

include { TRIM_SE } from "./modules/local/trim.nf"
include { FASTQC as FASTQC_RAW } from "./modules/local/qc.nf"
include { FASTQC as FASTQC_TRIMMED } from "./modules/local/qc.nf"
include { FASTQ_SCREEN } from "./modules/local/qc.nf"
include { ALIGN_BLACKLIST } from "./modules/local/qc.nf"
include { ALIGN_GENOME } from "./modules/local/qc.nf"
include { INDEX_BAM } from "./modules/local/qc.nf"
include { PRESEQ } from "./modules/local/qc.nf"
include { PHANTOM_PEAKS } from "./modules/local/qc.nf"
include { DEDUPLICATE } from "./modules/local/qc.nf"
include { NGSQC_GEN } from "./modules/local/qc.nf"
include { DEEPTOOLS_BAMCOV } from "./modules/local/qc.nf"
include { DEEPTOOLS_BIGWIG_SUM } from "./modules/local/qc.nf"

workflow {
  raw_fastqs = Channel
                    .fromPath(params.reads)
                    .map { file -> tuple(file.simpleName, file) }
  raw_fastqs.combine(Channel.value("raw")) | FASTQC_RAW
  raw_fastqs | TRIM_SE
  trimmed_fastqs = TRIM_SE.out
  trimmed_fastqs.combine(Channel.value("trimmed")) | FASTQC_TRIMMED
  //trimmed_fastqs = TRIM_SE.out | map { it -> it[1] } | collect // obtain list of just fastqs without sample_ids
  trimmed_fastqs.combine(Channel.fromPath(params.fastq_screen.conf)) | FASTQ_SCREEN
  blacklist_files = Channel
                    .fromPath("${params.align.index_dir}${params.align.blacklist}*")
                    .collect()
  ALIGN_BLACKLIST(trimmed_fastqs, blacklist_files)
  reference_files = Channel
                    .fromPath("${params.align.index_dir}${params.align.genome}*")
                    .collect()
  ALIGN_GENOME(ALIGN_BLACKLIST.out, reference_files)
  PRESEQ(ALIGN_GENOME.out)
  chrom_sizes = Channel.fromPath("${params.align.index_dir}${params.align.chrom_sizes}")
  ALIGN_GENOME.out.combine(chrom_sizes) | DEDUPLICATE
  INDEX_BAM(DEDUPLICATE.out.bam)
  //DEDUPLICATE.out.tag_align.combine(chrom_sizes) | NGSQC_GEN
  PHANTOM_PEAKS(INDEX_BAM.out.bam)
  DEEPTOOLS_BAMCOV(INDEX_BAM.out.bam, PHANTOM_PEAKS.out.ppqt)
  DEEPTOOLS_BAMCOV.out.bigwig.collect() | DEEPTOOLS_BIGWIG_SUM
}
