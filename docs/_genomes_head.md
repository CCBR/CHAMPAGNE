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
