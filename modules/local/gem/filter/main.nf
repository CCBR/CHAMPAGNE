process FILTER_GEM {
    tag { meta.id }

    container "${params.containers_base}"

    input:
        tuple val(meta), path(peak), val(tool), path(chrom_sizes)

    output:
        tuple val(meta), path("${peak}.filtered"), val(tool), emit: peak

    script:
    """
    #!/usr/bin/env python

    chrom_ends = dict()
    with open('${chrom_sizes}', 'r') as chrom_file:
        for line in chrom_file:
            chrom, end = line.split()
            chrom_ends[chrom] = int(end)

    count_bad_peaks = 0
    with open('${peak}', 'r') as infile:
        with open('${peak}.filtered', 'w') as outfile:
            for line in infile:
                line_split = line.split()
                chrom = line_split[0]
                start = int(line_split[1])
                end = int(line_split[2])
                if start > 0 and end < chrom_ends[chrom]:
                    outfile.write(line)
                else:
                    count_bad_peaks += 1
    print(f"Filtered out {count_bad_peaks} peaks")
    """
    stub:
    """
    touch ${peak}.filtered
    """

}
