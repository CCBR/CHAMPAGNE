process CONCAT_JACCARD {
    label 'peaks'
    label 'process_single'

    container "${params.containers_base}"

    input:
        path(jaccards)

    output:
        path("jaccard_all.txt")

    script:
    """
    echo -e "fileA\\tlabelA\\ttoolA\\tfileB\\tlabelB\\ttoolB\\tintersection\\tunion\\tjaccard\\tn_intersections" > jaccard_all.txt
    cat ${jaccards} |\\
      sort -k 1,1 -k 2,2 >>\\
      jaccard_all.txt
    """
    stub:
    """
    touch jaccard_all.txt
    """
}
