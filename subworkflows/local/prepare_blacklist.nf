
include { BEDTOOLS_GETFASTA          } from '../../modules/nf-core/bedtools/getfasta/main'
include { BWA_INDEX as BWA_INDEX_BL } from "../../modules/CCBR/bwa/index"
include { GUNZIP_REFERENCE as GUNZIP_BLACKLIST
          RENAME_FASTA_CONTIGS as RENAME_FASTA_CONTIGS_BL } from "../../modules/local/prepare_genome.nf"

workflow PREPARE_BLACKLIST {
    take:
        blacklist_file // bed or fasta
        genome_fasta
        rename_contigs // optional
    main:

        blacklist_path = file(blacklist_file, checkIfExists: true)
        blacklist_extension = blacklist_path.extension
        ch_blacklist_input = Channel.fromPath(blacklist_path)
        if (blacklist_extension == 'gz') {
            blacklist_extension = blacklist_path.name.toLowerCase().replaceFirst(/\.gz$/, '').tokenize('.').last()
            ch_blacklist_input = GUNZIP_BLACKLIST(ch_blacklist_input).uncompressed
        }

        // Convert BED intervals to fasta before indexing.
        if (blacklist_extension == 'bed') {
            BEDTOOLS_GETFASTA(ch_blacklist_input, genome_fasta)
            ch_blacklist_input = BEDTOOLS_GETFASTA.out.fasta
        } else if (blacklist_extension != 'fasta' && blacklist_extension != 'fa') {
            error "Unsupported blacklist file format extension: ${blacklist_extension}. Expected .bed, .fasta, or .fa, optionally compressed with .gz"
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
