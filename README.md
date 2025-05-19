# CHAMPAGNE 🍾

**CH**rom**A**tin i**M**muno **P**recipit**A**tion sequencin**G** a**N**alysis pip**E**line

[![build](https://github.com/CCBR/CHAMPAGNE/actions/workflows/build.yml/badge.svg)](https://github.com/CCBR/CHAMPAGNE/actions/workflows/build.yml)
[![docs](https://github.com/CCBR/CHAMPAGNE/actions/workflows/docs-mkdocs.yml/badge.svg)](https://ccbr.github.io/CHAMPAGNE)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.10516079.svg)](https://doi.org/10.5281/zenodo.10516079)
[![release](https://img.shields.io/github/v/release/CCBR/CHAMPAGNE?color=blue&label=latest%20release)](https://github.com/CCBR/CHAMPAGNE/releases/latest)

🚧 **This project is under active development. It is not yet ready for production use.** 🚧

## Set up

Champagne is installed on the [Biowulf HPC](#biowulf).
For installation in other execution environments,
refer to the [docs](https://ccbr.github.io/CHAMPAGNE/).

### Biowulf

Champagne is available on [Biowulf](https://hpc.nih.gov/) in the `ccbrpipeliner` module.
You'll first need to start an interactive session and create a directory from where you'll run champagne.

```sh
# start an interactive node
sinteractive --mem=2g --cpus-per-task=2 --gres=lscratch:200
# make a working directory for your project and go to it
mkdir -p /data/$USER/chipseq
cd /data/$USER/chipseq
# load the ccbrpipeliener module
module load ccbrpipeliner
```

## Usage

Initialize and run champagne with test data:

```sh
# copy the champagne config files to your project directory.
# --output is optional and defaults to your current working directory.
champagne init --output /data/$USER/champagne_project
# preview the champagne jobs that will run with the test dataset
champagne run --output /data/$USER/champagne_project --mode local -profile test -preview
# launch a champagne run on slurm with the test dataset
champagne run --output /data/$USER/champagne_project --mode slurm -profile test,biowulf
```

To run champagne on your own data, you'll need to create a sample sheet.
Take a look at these examples:

- [assets/samplesheet_test.csv](/assets/samplesheet_test.csv) - mix of single and paired end reads downloaded from github.
- [assets/samplesheet_mm10.csv](/assets/samplesheet_test.csv) - single end reads on biowulf.

Once you've created a samplesheet with paths to your fastq files,
run champagne with the `--input` option to specify the path to your sample sheet:

```sh
champagne run --output /data/$USER/champagne_project --mode slurm -profile biowulf --input samplesheet.csv --genome hg38
```

We currently support the hg38 and mm10 genomes.
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

The reference files and a config file for the genome will be written in `custom_genome/genome`.

Then you can run champagne using your custom genome:

```sh
champagne run --output /data/$USER/champagne_project \
    --mode slurm -profile biowulf \
    --input samplesheet.csv \
    --genome custom_genome \
    -c custom_genome/genome/custom_genome.config
```

## Help & Contributing

Come across a **bug**? Open an [issue](https://github.com/CCBR/CHAMPAGNE/issues) and include a minimal reproducible example.

Have a **question**? Ask it in [discussions](https://github.com/CCBR/CHAMPAGNE/discussions).

Want to **contribute** to this project? Check out the [contributing guidelines](.github/CONTRIBUTING.md).

**General Inquiries and Collaboration:** Please contact the CCBR Pipeliner team at [CCBR_Pipeliner@mail.nih.gov](mailto:CCBR_Pipeliner@mail.nih.gov).

## References

This repo was originally generated from the
[CCBR Nextflow Template](https://github.com/CCBR/CCBR_NextflowTemplate).
The template takes inspiration from nektool[^1] and the nf-core template.
If you plan to contribute your pipeline to nf-core, don't use this template --
instead follow nf-core's instructions[^2].

[^1]: nektool https://github.com/beardymcjohnface/nektool
[^2]: instructions for nf-core pipelines https://nf-co.re/docs/contributing/tutorials/creating_with_nf_core
