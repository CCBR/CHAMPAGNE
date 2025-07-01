# Genomes

<!--
This file is created by concatenating _genomes_head.md and the auto-generated genomes list.
Do not edit guide/genomes.md manually.
-->

### Custom reference genome

If you'd like to use a genome not available on Biowulf (see list below),
you can prepare a custom genome with the `MAKE_REFERENCE` entrypoint.
If you'd like to use a custom genome, you'll need the following files:

- genome fasta
- genome GTF
- blacklist fasta

Prepare your custom reference genome with:

```sh
champagne run --output /data/$USER/champagne_project \
    --mode slurm -profile biowulf \
    -entry MAKE_REFERENCE \
    --outdir custom_genome \
    --genome custom_genome \
    --genome_fasta genome.fasta \
    --genes_gtf genome.gtf \
    --blacklist blacklist.fasta
```

The reference files and a config file for the genome will be written in `results/genome/custom_genome/`.

Then you can run champagne using your custom genome:

```sh
champagne run --output /data/$USER/champagne_project \
    --mode slurm -profile biowulf \
    --input samplesheet.csv \
    --genome custom_genome \
    -c results/genome/custom_genome/custom_genome.config
```

## Available genomes

These genomes are available on biowulf.

### Reference Genomes

These genomes can be passed to the `--genome` parameter.

- `hg38`

  - species: `Homo sapiens`
  - fasta: `${params.index_dir}/hg38_basic/hg38_basic.fa`
  - genes_gtf: `${params.index_dir}/hg38_basic/genes.gtf`
  - blacklist_index: `${params.index_dir}/hg38_basic/indexes/blacklist/hg38.blacklist_v3.chrM.chr_rDNA.*`
  - reference_index: `${params.index_dir}/hg38_basic/bwa_index/hg38*`
  - chromosomes_dir: `${params.index_dir}/hg38_basic/Chromsomes/`
  - chrom_sizes: `${params.index_dir}/hg38_basic/indexes/hg38.fa.sizes`
  - gene_info: `${params.index_dir}/hg38_basic/geneinfo.bed`
  - effective_genome_size: `2700000000`
  - meme_motifs: `${projectDir}/assets/HOCOMOCOv11_core_HUMAN_mono_meme_format.tar.gz`
  - bioc_txdb: `TxDb.Hsapiens.UCSC.hg38.knownGene`
  - bioc_annot: `org.Hs.eg.db`

- `mm10`

  - species: `Mus musculus`
  - fasta: `${params.index_dir}/mm10_basic/mm10_basic.fa`
  - genes_gtf: `${params.index_dir}/mm10_basic/genes.gtf`
  - blacklist_index: `${params.index_dir}/mm10_basic/indexes/blacklist/mm10.blacklist.chrM.chr_rDNA.*`
  - reference_index: `${params.index_dir}/mm10_basic/indexes/reference/mm10*`
  - chromosomes_dir: `${params.index_dir}/mm10_basic/Chromsomes/`
  - chrom_sizes: `${params.index_dir}/mm10_basic/indexes/mm10.fa.sizes`
  - gene_info: `${params.index_dir}/mm10_basic/geneinfo.bed`
  - effective_genome_size: `2400000000`
  - meme_motifs: `${projectDir}/assets/HOCOMOCOv11_core_MOUSE_mono_meme_format.tar.gz`
  - bioc_txdb: `TxDb.Mmusculus.UCSC.mm10.knownGene`
  - bioc_annot: `org.Mmu.eg.db`

### Spike-in Genomes

These genomes can be passed to the `--spike_genome` parameter.

- `dmelr6.32`

  - species: `Drosophila melanogaster`
  - fasta: `${params.index_dir}/dmelr6.32/indexes/dmelr6.32.fa`
  - reference_index: `${params.index_dir}/dmelr6.32/indexes/bwa/Drosophila_melanogaster.*`
  - blacklist_index: `${params.index_dir}/dmelr6.32/indexes/blacklist/dmelr6.32.blacklist.*`
  - blacklist_bed: `${params.index_dir}/dmelr6.32/indexes/dm6-blacklist.v2.no_chr.bed.gz`

- `ecoli_k12`

  - species: `Escherichia coli K-12`
  - fasta: `${params.index_dir}/ecoli_k12/indexes/ecoli_k12.fa`
  - reference_index: `${params.index_dir}/ecoli_k12/indexes/ecoli_k12.*`
  - blacklist_bed: `NO_FILE`
