# How to set pipeline parameters

Any parameter can be set via the CLI using two hyphens (`--`) followed by the
parameter name and value. For example:

```sh
champagne run --output /data/$USER/champagne_project \
    --input assets/samplesheet_full_mm10.csv \
    --contrasts assets/contrasts_full_mm10.csv \
    --genome mm10 \
    --run_gem false \
    --run_chipseeker false \
    --run_qc true
```

Alternatively, you can create a YAML file with the parameters you want to set.
This is useful for managing multiple parameters or for sharing configurations
with others. Here's an example YAML file with some common parameters:

`assets/params.yml`

```YAML
input: './assets/samplesheet_full_mm10.csv'
contrasts: './assets/contrasts_full_mm10.csv'
genome: mm10
run_gem: false
run_chipseeker: false
run_qc: true
```

You can then use these parameters with the `-params-file` option:

```sh
champagne run --output /data/$USER/champagne_project \
    -params-file assets/params.yml
```

View the full list of pipeline parameters below.

<!-- This doc is generated by: nf-core pipelines schema docs. Edit parameter descriptions in nextflow_schema.json -->
