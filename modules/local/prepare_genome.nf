
process DOWNLOAD_GENOME {
    """
    Prepare a reference asset (fasta, gtf, or blacklist) for the build chain.
    The remote URL is staged by Nextflow (native http/https/ftp/s3 support); this
    process verifies an optional md5 checksum and decompresses gzipped files so the
    downstream build tools (which read plain text) can consume them.
    """
    tag { meta }
    label 'process_single'

    container "${params.containers_base}"

    errorStrategy 'retry'
    maxRetries 2

    input:
        tuple val(meta), path(archive), val(md5)

    output:
        // output name drops any .gz suffix; derived from the staged input so it is
        // resolvable in the output block regardless of the script/stub branch
        tuple val(meta), path("${ archive.name.endsWith('.gz') ? archive.baseName : archive.name }"), emit: file

    script:
    def outname = archive.name.endsWith('.gz') ? archive.baseName : archive.name
    """
    if [ -n "${md5}" ]; then
        echo "${md5}  ${archive}" | md5sum -c -
    fi

    if [[ "${archive}" == *.gz ]]; then
        zcat "${archive}" > "${outname}"
    else
        # materialize a copy under a temp name to avoid read==write on the staged input
        cp -L "${archive}" "${outname}.tmp" && mv "${outname}.tmp" "${outname}"
    fi
    """

    stub:
    def outname = archive.name.endsWith('.gz') ? archive.baseName : archive.name
    """
    # materialize a real output file (via a temp name) so it never collides with,
    # or remains a symlink to, the staged input
    cp -L "${archive}" "stub.download" && mv "stub.download" "${outname}"
    """
}

process GTF2BED {
    tag { gtf }
    label 'process_single'

    container 'nciccbr/ccbr_ubuntu_base_20.04:v5'

    input:
        path(gtf)

    output:
        path("${gtf.baseName}.bed"), emit: bed

    script:
    """
    cat ${gtf} | gtf2bed > ${gtf.baseName}.bed

    """
    stub:
    """
    touch ${gtf.baseName}.bed
    """
}
process SPLIT_REF_CHROMS {
    tag { fasta }
    label 'process_single'
    container "${params.containers_base}"

    input:
        path(fasta)

    output:
        path("${fasta.baseName}.chrom.sizes"), emit: chrom_sizes
        path("chroms/")                      , emit: chrom_dir

    script:
    """
    splitRef.py ${fasta} ${fasta.baseName}.chrom.sizes chroms
    """
    stub:
    """
    touch ${fasta.baseName}.chrom.sizes
    mkdir -p chroms/
    touch chroms/chr1.fa
    """
}

process RENAME_FASTA_CONTIGS {
    """
    Convert ensembl to UCSC contig names in a fasta file
    """
    tag { fasta }

    container "${params.containers_base}"

    input:
        path(fasta)
        path(map)

    output:
        path("*_renamed*"), emit: fasta

    script:
    def renamed_fasta= "${fasta.getSimpleName()}_renamed.${fasta.getExtension()}"
    """
    #!/usr/bin/env python

    with open("${map}", "r") as mapfile:
        contig_map = {line.strip().split()[0]: line.strip().split()[1] for line in mapfile}

    with open("${fasta}", "r") as infile:
        with open("${renamed_fasta}", "w") as outfile:
            for line in infile:
                if line.startswith(">"):
                    old_contig = line.strip(">").strip()
                    contig = contig_map[old_contig] if old_contig in contig_map.keys() else old_contig
                    outfile.write(f">{contig}\\n")
                else:
                    outfile.write(line)

    """

    stub:
    def renamed_fasta= "${fasta.getSimpleName()}_renamed.${fasta.getExtension()}"
    """
    touch ${renamed_fasta}
    """
}

process RENAME_DELIM_CONTIGS {
    """
    Convert ensembl to UCSC contig names in a delimited file (e.g. GTF, BED)
    using cvbio https://github.com/clintval/cvbio#updatecontignames
    """
    tag { delim }

    container "nciccbr/ccbr_cvbio_3.0.0:v1.0.1"

    input:
        path(delim)
        path(map)

    output:
        path("*_renamed*"), emit: delim

    script:
    def renamed_delim = "${delim.getSimpleName()}_renamed.${delim.getExtension()}"
    """
    cvbio UpdateContigNames \\
        -i ${delim} \\
        -o ${renamed_delim} \\
        -m ${map} \\
        --comment-chars '#' \\
        --columns 0 \\
        --skip-missing false
    """

    stub:
    def renamed_delim = "${delim.getSimpleName()}_renamed.${delim.getExtension()}"
    """
    touch ${renamed_delim}
    """
}

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
        path("${params.genome ?: 'custom_genome'}/"), emit: files

    script:
    def genome_name = params.genome ?: 'custom_genome'
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
                  bioc_txdb = "${bioc_txdb}",
                  bioc_annot = "${bioc_annot}"
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
    def genome_name = params.genome ?: 'custom_genome'
    """
    mkdir ${genome_name}/
    touch ${genome_name}.config ${genome_name}/genome.fa
    """
}
