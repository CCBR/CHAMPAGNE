
include { BEDTOOLS_GETFASTA          } from '../../modules/nf-core/bedtools/getfasta/main'
include { BWA_INDEX as BWA_INDEX_BL } from "../../modules/CCBR/bwa/index"
include { RENAME_FASTA_CONTIGS as RENAME_FASTA_CONTIGS_BL } from "../../modules/local/prepare_genome.nf"

workflow PREPARE_BLACKLIST {
    take:
        blacklist_file // bed or fasta
        genome_fasta
        rename_contigs // optional
    main:

        // blacklist bed to fasta
        if (blacklist_file.extension == 'bed') {
            BEDTOOLS_GETFASTA(blacklist_file, genome_fasta)
            ch_blacklist_input = BEDTOOLS_GETFASTA.out.fasta
        } else if (blacklist_file.extension == 'fasta' || blacklist_file.extension == 'fa') {
            ch_blacklist_input = Channel.fromPath(blacklist_file)
        } else {
            error "Unsupported blacklist file format extension: ${blacklist_file.extension}. Expected .bed or .fasta/.fa"
        }
        if (rename_contigs) {
            contig_map = file(rename_contigs, checkIfExists: true)
            ch_blacklist_fasta = RENAME_FASTA_CONTIGS_BL(ch_blacklist_input, contig_map).fasta
        } else {
            ch_blacklist_fasta = ch_blacklist_input
        }

        blacklist_meta = ch_blacklist_fasta.map{ it -> [it.baseName, it]}
        ch_blacklist_index =  BWA_INDEX_BL(blacklist_meta).index.collect()
    emit:
        index = ch_blacklist_index
}
