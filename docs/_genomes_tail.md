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
    --blacklist blacklist.bed
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

Alternatively, you can build the reference genome and run the rest of the
pipeline in one shot by specifying the custom files like so:

```sh
champagne run --output /data/$USER/champagne_project \
    --mode slurm \
    --genome custom_genome \
    --genome_fasta genome.fasta \
    --genes_gtf genome.gtf \
    --blacklist blacklist.bed
```
