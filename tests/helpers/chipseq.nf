process GENERATE_CHIPSEQ {
    label 'process_single'
    container 'nciccbr/ccbr_ubuntu_base_20.04:v6.1'

    input:
    val(meta)

    output:
    tuple val(meta), path("${meta.id}.bam"), path("${meta.id}.bam.bai"), emit: bam
    tuple val(meta), path("${meta.id}.bed"), emit: reads
    tuple val(meta), path("${meta.id}.narrowPeak"), emit: peaks
    tuple val(meta), path("${meta.id}.fastq.gz"), emit: fastq
    path 'genome.fa', emit: fasta
    path 'genome.sizes', emit: sizes
    path 'genes.bed', emit: genes
    path 'motifs.motif', emit: homer_motifs
    path 'motifs.tar.gz', emit: meme_motifs

    script:
    """
    python3 - <<'PY'
    import gzip
    import io
    import random
    import tarfile
    import pysam

    sample = '${meta.id}'
    group = '${meta.group}'
    randomizer = random.Random(42)
    reference = ''.join(randomizer.choice('ACGT') for _ in range(100000))
    with open('genome.fa', 'w') as output:
        output.write('>chr1\\n' + reference + '\\n')
    with open('genome.sizes', 'w') as output:
        output.write('chr1\\t100000\\n')
    with open('genes.bed', 'w') as output:
        output.write('chr1\\t1000\\t5000\\t+\\tgene1\\tprotein_coding\\nchr1\\t50000\\t55000\\t+\\tgene2\\tprotein_coding\\n')
    matrix = '\\n'.join(' '.join('0.97' if base == expected else '0.01' for base in 'ACGT') for expected in 'ACGTGC') + '\\n'
    with open('motifs.motif', 'w') as output:
        output.write('>ACGTGC\\ttest\\t1\\n' + matrix)
    motif = ('MEME version 4\\n\\nALPHABET= ACGT\\n\\nstrands: + -\\n\\nBackground letter frequencies\\nA 0.25 C 0.25 G 0.25 T 0.25\\n\\nMOTIF test\\nletter-probability matrix: alength= 4 w= 6 nsites= 20 E= 0\\n' + matrix).encode()
    with tarfile.open('motifs.tar.gz', 'w:gz', format=tarfile.USTAR_FORMAT) as archive:
        entry = tarfile.TarInfo('test.meme')
        entry.size = len(motif)
        archive.addfile(entry, io.BytesIO(motif))
    randomizer = random.Random(sample)
    header = {'HD': {'VN': '1.6', 'SO': 'unsorted'}, 'SQ': [{'SN': 'chr1', 'LN': 100000}], 'RG': [{'ID': sample, 'SM': sample}]}
    with pysam.AlignmentFile('unsorted.bam', 'wb', header=header) as output, open(sample + '.bed', 'w') as tags, open(sample + '.narrowPeak', 'w') as peaks, gzip.open(sample + '.fastq.gz', 'wt') as fastq:
        for peak in range(100):
            start = 1000 + peak * 500
            if group == 'group2' and peak >= 80:
                start = 60000 + (peak - 80) * 500
            peaks.write(f'chr1\\t{start}\\t{start + 200}\\tpeak{peak}\\t100\\t.\\t10\\t8\\t6\\t100\\n')
            enriched = (group == 'group1' and peak < 50) or (group == 'group2' and peak >= 50)
            background_count = 20 if group == 'input' else 2
            count = (250 if enriched else background_count) + randomizer.randint(0, 20 if enriched else 2)
            for read in range(count):
                position = start + randomizer.randint(0, 100)
                name = f'{sample}_{peak}_{read}'
                sequence = reference[position:position + 50]
                record = pysam.AlignedSegment()
                record.query_name = name
                record.query_sequence = sequence
                record.flag = 0
                record.reference_id = 0
                record.reference_start = position
                record.mapping_quality = 60
                record.cigarstring = '50M'
                record.query_qualities = pysam.qualitystring_to_array('I' * 50)
                record.set_tag('RG', sample)
                output.write(record)
                tags.write(f'chr1\\t{position}\\t{position + 50}\\t{name}\\t0\\t+\\n')
                fastq.write(f'@{name}\\n{sequence}\\n+\\n' + 'I' * 50 + '\\n')
    pysam.sort('-o', sample + '.bam', 'unsorted.bam')
    pysam.index(sample + '.bam')
    PY
    """
}
