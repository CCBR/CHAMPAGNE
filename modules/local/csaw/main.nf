process CSAW_NORMFACTORS {

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path("*.csv")

    script:
    bam_files = bam.join(',')
    outfile = 'norm_factors.csv'
    template 'csaw_normfactors.R'
}

process CSAW_CONTRAST {
    tag { meta.group }
}