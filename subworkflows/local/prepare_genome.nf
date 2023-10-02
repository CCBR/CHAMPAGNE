workflow PREPARE_GENOME {
    main:
        if (params.fasta && params.gtf) {
            ch_fasta = file(params.fasta)
            ch_gtf = file(params.gtf)
        } else {
            Channel.fromPath(params.genomes[ params.genome ].blacklist_files, checkIfExists: true)
                .collect()
                .set{ ch_blacklist_files }
            Channel.fromPath(params.genomes[ params.genome ].reference_files, checkIfExists: true)
                .collect()
                .set{ ch_reference_files }
            Channel.fromPath(params.genomes[ params.genome ].chrom_sizes, checkIfExists: true)
                .set{ ch_chrom_sizes }
        }

    emit:
        blacklist_files = ch_blacklist_files
        reference_files = ch_reference_files
        chrom_sizes = ch_chrom_sizes
}
