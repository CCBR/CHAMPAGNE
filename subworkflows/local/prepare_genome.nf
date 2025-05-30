include { BWA_INDEX as BWA_INDEX_BL
          BWA_INDEX as BWA_INDEX_REF } from "../../modules/CCBR/bwa/index"
include { KHMER_UNIQUEKMERS          } from '../../modules/CCBR/khmer/uniquekmers'
include { BEDTOOLS_GETFASTA          } from '../../modules/nf-core/bedtools/getfasta/main'
include { SPLIT_REF_CHROMS
          RENAME_FASTA_CONTIGS as RENAME_FASTA_CONTIGS_REF
          RENAME_FASTA_CONTIGS as RENAME_FASTA_CONTIGS_BL
          RENAME_DELIM_CONTIGS
          GTF2BED
          WRITE_GENOME_CONFIG } from "../../modules/local/prepare_genome.nf"

workflow PREPARE_GENOME {
    main:
        if (params.genomes[ params.genome ]) {
            println "Using ${params.genome} as the reference"

            ch_fasta = Channel.fromPath(params.genomes[ params.genome ].fasta, checkIfExists: true)
            ch_genes_gtf = Channel.fromPath(params.genomes[ params.genome ].genes_gtf, checkIfExists: true)

            ch_blacklist_index = Channel.fromPath(params.genomes[ params.genome ].blacklist_index, checkIfExists: true)
                .collect()
                .map{ file ->
                    [file.baseName, file]
                }
            ch_reference_index = Channel.fromPath(params.genomes[ params.genome ].reference_index, checkIfExists: true)
                .collect()
                .map{ file ->
                    [file.baseName, file]
                }
            ch_chrom_dir = Channel.fromPath("${params.genomes[ params.genome ].chromosomes_dir}", type: 'dir', checkIfExists: true)
            ch_chrom_sizes = Channel.fromPath(params.genomes[ params.genome ].chrom_sizes, checkIfExists: true)
            ch_gene_info = Channel.fromPath(params.genomes[ params.genome ].gene_info, checkIfExists: true)
            ch_gsize = Channel.value(params.genomes[ params.genome ].effective_genome_size)
            ch_meme_motifs = Channel.fromPath(params.genomes[ params.genome ].meme_motifs, checkIfExists: true)
            ch_bioc_txdb = Channel.value(params.genomes[ params.genome ].bioc_txdb)
            ch_bioc_annot = Channel.value(params.genomes[ params.genome ].bioc_annot)

        } else if (params.genome_fasta && params.genes_gtf && params.blacklist) {
            println "Building a reference from provided genome fasta, gtf, and blacklist files"
            fasta_file = Channel.fromPath(params.genome_fasta, checkIfExists: true)
            gtf_file = file(params.genes_gtf, checkIfExists: true)

            // blacklist bed to fasta
            blacklist_file = file(params.blacklist, checkIfExists: true)
            if (blacklist_file.endsWith('.bed')) {
                BEDTOOLS_GETFASTA(blacklist_file, fasta_file)
                ch_blacklist_input = BEDTOOLS_GETFASTA.out.fasta
            } else {
                ch_blacklist_input = Channel.fromPath(blacklist_file)
            }

            // rename contigs from ensembl to UCSC if needed
            if (params.rename_contigs) {
                contig_map = file(params.rename_contigs, checkIfExists: true)
                ch_fasta = RENAME_FASTA_CONTIGS_REF(fasta_file, contig_map).fasta
                ch_blacklist_fasta = RENAME_FASTA_CONTIGS_BL(ch_blacklist_input, contig_map).fasta
                ch_gtf = RENAME_DELIM_CONTIGS(gtf_file, contig_map).delim
            } else {
                ch_fasta = fasta_file
                ch_blacklist_fasta = ch_blacklist_input
                ch_gtf = gtf_file
            }

            blacklist_meta = ch_blacklist_fasta.map{ it -> [it.baseName, it]}
            fasta_meta = ch_fasta.map{ it -> [it.baseName, it]}

            ch_genes_gtf = Channel.fromPath(gtf_file)
            ch_blacklist_index =  BWA_INDEX_BL(blacklist_meta).index.collect()
            ch_reference_index = BWA_INDEX_REF(fasta_meta).index.collect()
            KHMER_UNIQUEKMERS(ch_fasta, params.read_length)
            ch_gsize = KHMER_UNIQUEKMERS.out.kmers.map { it.text.trim() }
            ch_gene_info = GTF2BED ( ch_gtf ).bed
            SPLIT_REF_CHROMS(ch_fasta)
            ch_chrom_sizes = SPLIT_REF_CHROMS.out.chrom_sizes
            ch_chrom_dir = SPLIT_REF_CHROMS.out.chrom_dir
            if (params.meme_motifs && file(params.meme_motifs).exists()) {
                meme_motif_name = Channel.value(params.meme_motifs)
                ch_meme_motifs = Channel.fromPath(params.meme_motifs)
            } else {
                meme_motif_name = 'null'
                ch_meme_motifs = Channel.empty()
                params.run_meme = false
            }
            ch_bioc_txdb = Channel.value(params.bioc_txdb)
            ch_bioc_annot = Channel.value(params.bioc_annot)

            WRITE_GENOME_CONFIG(
                ch_fasta,
                ch_genes_gtf,
                ch_reference_index,
                ch_blacklist_index,
                ch_chrom_sizes,
                ch_chrom_dir,
                ch_gene_info,
                ch_gsize,
                meme_motif_name,
                ch_bioc_txdb,
                ch_bioc_annot
            )
            println "Saving custom genome config in ${params.outdir}/genome"

        } else {
            error "Either specify a genome in `conf/genomes.conf`, or specify a genome fasta, gtf, and blacklist file to build a custom reference."
        }

    emit:
        fasta = ch_fasta
        blacklist_index = ch_blacklist_index
        reference_index = ch_reference_index
        chrom_sizes = ch_chrom_sizes
        chrom_dir = ch_chrom_dir
        gene_info = ch_gene_info
        effective_genome_size = ch_gsize
        meme_motifs = ch_meme_motifs
        bioc_txdb = ch_bioc_txdb
        bioc_annot = ch_bioc_annot
}
