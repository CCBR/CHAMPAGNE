process GUNZIP_REFERENCE {
    tag { compressed_file }
    label 'process_single'

    input:
        path(compressed_file)

    output:
        path("${compressed_file.name.replaceFirst(/\.gz$/, '')}"), emit: uncompressed

    script:
    def uncompressed_name = compressed_file.name.replaceFirst(/\.gz$/, '')
    """
    gzip -cd "${compressed_file}" > "${uncompressed_name}"
    """
}
