
include { BEDTOOLS_GETFASTA          } from '../../modules/nf-core/bedtools/getfasta/main'
include { BWA_INDEX as BWA_INDEX_BL } from "../../modules/CCBR/bwa/index"
include { RENAME_FASTA_CONTIGS as RENAME_FASTA_CONTIGS_BL } from "../../modules/local/prepare_genome.nf"

workflow PREPARE_BLACKLIST {
    take:
        blacklist_ch   // channel: blacklist file (bed or fasta/fa)
        genome_fasta
        rename_contigs // optional
    main:

        // split by file type; a downloaded blacklist arrives as a process-output
        // channel, so branch on the channel rather than a plain file property
        blacklist_ch
            .branch { f ->
                bed:   f.extension == 'bed'
                fasta: f.extension == 'fasta' || f.extension == 'fa'
                other: true
            }
            .set { bl }

        bl.other.map { error "Unsupported blacklist file format extension: ${it.extension}. Expected .bed or .fasta/.fa" }

        // blacklist bed to fasta
        ch_from_bed = BEDTOOLS_GETFASTA(bl.bed, genome_fasta).fasta
        ch_blacklist_input = ch_from_bed.mix(bl.fasta)

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
