# Genomes

<!--
This file is created by concatenating _genomes_tail.md and the auto-generated genomes list.
Do not edit guide/genomes.md manually.
-->

## Supported reference genomes

These genomes are available on biowulf.

### Reference Genomes

These genomes can be passed to the `--genome` parameter.

#### `hg38`

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
- fasta_url: `https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz`
- fasta_md5: `1c9dcaddfa41027f17cd8f7a82c7293b`
- gtf_url: `https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_45/gencode.v45.annotation.gtf.gz`
- gtf_md5: `b6eeb6c9791b7a43a5504a654ff09d9a`
- blacklist_url: `https://raw.githubusercontent.com/Boyle-Lab/Blacklist/master/lists/hg38-blacklist.v2.bed.gz`
- blacklist_md5: `83fe6bf8187a64dee8079b80f75ba289`
- read_length: `50`

#### `hg19`

- species: `Homo sapiens`
- fasta: `${params.index_dir}/hg19_basic/hg19.fa`
- genes_gtf: `${params.index_dir}/hg19_basic/genes.gtf`
- blacklist_index: `${params.index_dir}/hg19_basic/indexes/blacklist/hg19.blacklist.*`
- reference_index: `${params.index_dir}/hg19_basic/bwa_index/hg19.*`
- chromosomes_dir: `${params.index_dir}/hg19_basic/Chromosomes`
- chrom_sizes: `${params.index_dir}/hg19_basic/Chromosomes/chrom.sizes`
- gene_info: `${params.index_dir}/hg19_basic/geneinfo.bed`
- effective_genome_size: `2700000000`
- meme_motifs: `${projectDir}/assets/HOCOMOCOv11_core_HUMAN_mono_meme_format.tar.gz`
- bioc_txdb: `TxDb.Hsapiens.UCSC.hg38.knownGene`
- bioc_annot: `org.Hs.eg.db`

#### `mm10`

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

#### `dmelr6.32`

- species: `Drosophila melanogaster`
- fasta: `${params.index_dir}/dmelr6.32/indexes/dmelr6.32.fa`
- reference_index: `${params.index_dir}/dmelr6.32/indexes/bwa/Drosophila_melanogaster.*`
- blacklist_index: `${params.index_dir}/dmelr6.32/indexes/blacklist/dmelr6.32.blacklist.*`
- blacklist_bed: `${params.index_dir}/dmelr6.32/indexes/dm6-blacklist.v2.no_chr.bed.gz`
- effective_genome_size: `142573017`
- chrom_sizes: `${params.index_dir}/dmelr6.32/chrom_dmelr6.28.sizes`

#### `ecoli_k12`

- species: `Escherichia coli K-12`
- fasta: `${params.index_dir}/ecoli_k12/indexes/ecoli_k12.fa`
- reference_index: `${params.index_dir}/ecoli_k12/indexes/ecoli_k12.*`
- blacklist_bed: `NO_FILE`
- effective_genome_size: `4641652`
- chrom_sizes: `${params.index_dir}/ecoli_k12/Chromosomes/chrom.sizes`
## Obtaining reference genomes

CHAMPAGNE can obtain reference genomes three ways:

1. **Prebuilt shared assets (Biowulf).** With `-profile biowulf`, `index_dir` points at
   the pre-built CCBR indices and `--genome hg38` uses them directly. This is the fastest
   option and requires no downloads.
2. **Automatic download + build (portable).** When prebuilt assets are unavailable
   (i.e. `index_dir` is not set, such as off Biowulf) and the genome defines public
   download URLs in [`conf/genomes.config`](https://github.com/CCBR/CHAMPAGNE/blob/main/conf/genomes.config),
   CHAMPAGNE stages the reference files from canonical public sources (using Nextflow's
   native URL handling), verifies an md5 checksum for each, and builds all required
   indices automatically. For example:

   ```sh
   champagne run --output ./champagne_project \
       --mode local \
       --input samplesheet.csv \
       --genome hg38
   ```

   You can force this path even when `index_dir` is set with `--download_refs true`.
3. **Custom genome build.** Provide your own files with `-entry MAKE_REFERENCE`
   (see [Custom reference genome](#custom-reference-genome) below).

### Caching downloaded/built genomes

By default, Nextflow's `-resume` reuses built assets within a run's work directory.
For cross-run (and cross-user) reuse, opt in by setting `genome_cache_dir` to a path;
repeat runs with the same `--genome` then reuse the cached assets instead of rebuilding.
Point it at shared storage to share a single genome build across users:

```sh
champagne run --output ./champagne_project \
    --input samplesheet.csv \
    --genome hg38 \
    --genome_cache_dir /path/to/shared/champagne_genomes
```

When `genome_cache_dir` is unset (the default), caching is disabled.

### Sharing a built genome as a bundle

Running `-entry MAKE_REFERENCE --genome hg38` downloads and builds the complete
reference under `results/genome/hg38/` and writes its config to
`results/genome/hg38.config`. These outputs can be archived (e.g. on a durable
mirror) and reused directly:

```sh
champagne run --output ./champagne_project \
    --input samplesheet.csv \
    --genome hg38 \
    -c results/genome/hg38.config
```

### Custom blacklist

If you'd like to override the default blacklist used by one of the built-in genomes,
you can provide a custom blacklist bed file or fasta file:

```sh
champagne run --output /data/$USER/champagne_project \
    --mode slurm \
    --genome hg38 \
    --blacklist /path/to/blacklist.bed
```

If you're providing a custom blacklist bed file, make sure its regions refer to
the genome version you're using.

### Custom reference genome

If you'd like to use a genome not available on Biowulf,
you can prepare a custom genome with the `MAKE_REFERENCE` entrypoint.
If you'd like to use a custom genome, you'll need the following files:

- genome fasta
- genome GTF
- blacklist fasta or bed (optional)

Prepare your custom reference genome with:

```sh
champagne run --output /data/$USER/champagne_project \
    --mode slurm \
    -entry MAKE_REFERENCE \
    --genome custom_genome \
    --genome_fasta genome.fasta \
    --genes_gtf genome.gtf \
    --blacklist blacklist.fasta
```

The reference files will be written in `results/genome/custom_genome/` and the
config will be written to `results/genome/custom_genome.config`.

Then you can run champagne using your custom genome:

```sh
champagne run --output /data/$USER/champagne_project \
    --mode slurm -profile biowulf \
    --input samplesheet.csv \
    --genome custom_genome \
    -c results/genome/custom_genome.config
```
