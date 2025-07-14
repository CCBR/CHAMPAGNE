## Spike-in normalization

CHAMPAGNE supports ChIP-seq experiments that spike-in reads from alternate species.
The data are normalized based on the number of reads aligning to the spike-in
genome to account for differences in sequencing depth or other technical
variations between samples.

### Spike-in options

You must set the `spike_genome` parameter to the name of a [supported genome](genomes.md#spike-in-genomes)
(e.g. `dmelr6.32`, `ecoli_k12`) that is different from the `genome` used for the
main analysis.
When using spike-in normalizations, we recommend setting
`deeptools_normalize_using` to `None` so that additional normalization isn't
performed (see [this
discussion](https://www.github.com/deeptools/deepTools/issues/1073#issuecomment-859326520)).

View the [spike-in options](params.md#spike-in-options) for a full list of
parameters that can be set for spike-in normalization.

#### normalization method

CHAMPAGNE implements two methods for spike-in normalization:

- **guenther**: This method is described in the supplementary material of
  [10.1016/j.celrep.2014.10.018](https://doi.org/10.1016/j.celrep.2014.10.018).
  Reads are scaled by the minimum number of reads aligning to the spike-in
  genome across all samples. To use this method, set the `spike_norm_method`
  parameter to `guenther`.
- **delorenzi**: This method uses [`deepTools multiBamSummary
--scalingFactors`](https://deeptools.readthedocs.io/en/develop/content/tools/multiBamSummary.html#output-optional-options)
  to calculate the scaling factors, which is similar to the method described
  here: [10.1101/gr.168260.113](https://doi.org/10.1101/gr.168260.113). To use
  this method, set the `spike_norm_method` parameter to `delorenzi`.

### Examples

Using the guenther normalization method with _D. melanogaster_ as the spike-in genome:

```sh
champagne run \
    --output /data/$USER/champagne_project/ \
    --genome hg38 \
    --input assets/samplesheet_full_spikein.csv \
    --spike_genome dmelr6.32 \
    --deeptools_normalize_using None \
    --spike_norm_method guenther
```

Using the delorenzi normalization method with _E. coli_ as the spike-in genome:

```sh
champagne run \
    --output /data/$USER/champagne_project/ \
    --genome hg38 \
    --input assets/samplesheet_full_spikein.csv \
    --spike_genome ecoli_k12 \
    --deeptools_normalize_using None \
    --spike_norm_method delorenzi
```
