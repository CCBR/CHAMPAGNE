### Custom blacklist

If you'd like to override the default blacklist used by one of the built-in genomes,
you can provide a custom blacklist bed file or fasta file:

```sh
champagne run --output path/to/champagne_project/ \
    --mode slurm \
    --genome hg38 \
    --blacklist path/to/blacklist.bed
```

If you're providing a custom blacklist bed file, make sure its regions refer to
the genome version you're using.

### Custom reference genome

If you'd like to use a genome not available on Biowulf,
you can prepare a custom genome with the `MAKE_REFERENCE` entrypoint.
If you'd like to use a custom genome, you'll need the following files:

- genome fasta
- genome GTF
- blacklist fasta

Prepare your custom reference genome with:

```sh
champagne run --output path/to/champagne_project/ \
    --mode slurm \
    -entry MAKE_REFERENCE \
    --genome custom_genome \
    --genome_fasta genome.fasta \
    --genes_gtf genome.gtf \
    --blacklist blacklist.fasta
```

The reference files and a config file for the genome will be written in `results/genome/custom_genome/`.

Then you can run champagne using your custom genome:

```sh
champagne run --output path/to/champagne_project/ \
    --mode slurm -profile biowulf \
    --input samplesheet.csv \
    --genome custom_genome \
    -c results/genome/custom_genome/custom_genome.config
```
