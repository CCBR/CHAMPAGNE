process WRITE_GENOME_CONFIG {
    label 'process_single'
    container "${params.containers_base}"

    input:
        path(fasta)
        path(gtf)
        tuple val(meta_ref), path(reference_index)
        tuple val(meta_bl), path(blacklist_index)
        path(chrom_sizes)
        path(chrom_dir)
        path(gene_info)
        val(effective_genome_size)
        val(meme_motifs)
        val(bioc_txdb)
        val(bioc_annot)


    output:
        path("*.config"), emit: conf
        path("custom_genome/"), emit: files // TODO can't use genome_name variable here, nextflow thinks it's null??

    script:
    def genome_name = 'custom_genome'
    """
    #!/usr/bin/env python
    import os
    import pprint
    import shutil
    print("${meme_motifs}")
    os.makedirs("${genome_name}/")
    for subdir, filelist in (('reference/', "${reference_index}"), ('blacklist', "${blacklist_index}")):
        dirpath = f"${{genome_name}}/{subdir}"
        os.mkdir(dirpath)
        for file in filelist.split():
            shutil.copy(file, dirpath)
    shutil.copytree("${chrom_dir}", '${genome_name}/chroms/')
    for file in ("${fasta}", "${gtf}", "${chrom_sizes}", "${gene_info}"):
        shutil.copy(file, "${genome_name}/")

    genome = dict(fasta = '"\${params.index_dir}/${genome_name}/${fasta}"',
                  genes_gtf = '"\${params.index_dir}/${genome_name}/${gtf}"',
                  reference_index = '"\${params.index_dir}/${genome_name}/reference/*"',
                  blacklist_index = '"\${params.index_dir}/${genome_name}/blacklist/*"',
                  chromosomes_dir = '"\${params.index_dir}/${genome_name}/chroms/"',
                  chrom_sizes = '"\${params.index_dir}/${genome_name}/${chrom_sizes}"',
                  gene_info = '"\${params.index_dir}/${genome_name}/${gene_info}"',
                  effective_genome_size = "${effective_genome_size}",
                  meme_motifs = "${meme_motifs}",
                  bioc_txdb = 'null' if "${bioc_txdb}" == 'null' else '"${bioc_txdb}"',
                  bioc_annot = 'null' if "${bioc_annot}" == 'null' else '"${bioc_annot}"'
    )
    pprint.pprint(genome)
    with open('${genome_name}.config', 'w') as conf_file:
        head = ["params {\\n",
                '\\tindex_dir = "\${outputDir}/genome/"\\n',
                "\\tgenomes {\\n"
                "\\t\\t'${genome_name}' {\\n"]
        conf_file.writelines(head)
        for k, v in genome.items():
            conf_file.write(f'\\t\\t\\t{k} = {v}\\n')
        tail = ["\\t\\t}\\n",
                "\\t}\\n",
                "}\\n"]
        conf_file.writelines(tail)
    """

    stub:
    """
    mkdir custom_genome/
    touch custom_genome.config custom_genome/genome.fa
    """
}
