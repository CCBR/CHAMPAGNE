#!/usr/bin/env nextflow

include { CHIPSEQ } from '../../../main.nf'

workflow test_qc_stats {
    old_qc_table = file('tests/workflow/qc/QCTable.txt', checkIfExists: true)
    old_qc_table.copyTo(file('output/old_qc_table.txt'))
    CHIPSEQ()
}
